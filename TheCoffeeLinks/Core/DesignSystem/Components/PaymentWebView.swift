//
//  PaymentWebView.swift
//  thecoffeelinks-client-ios
//

import SwiftUI
import WebKit

struct PaymentWebView: UIViewRepresentable {
    let url: URL
    let onComplete: (PaymentResult) -> Void
    let onCancel: () -> Void
    
    enum PaymentResult {
        case success(String) // orderId
        case failure(String) // error message
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PaymentWebView
        
        init(_ parent: PaymentWebView) {
            self.parent = parent
        }
        
        private func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                // Check if this is the callback URL
                if url.path.contains("/api/payments/vnpay/callback") {
                    // Start a timer to check content if needed, or wait for navigation to finish
                    // For now, let's allow it to finish and read content in didFinish
                    decisionHandler(.allow)
                    return
                }
                
                // Allow user to cancel within the webview if there's a cancel button that redirects back to app
                // Or if they close the sheet (handled by SwiftUI)
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url else { return }
            
            if url.path.contains("/api/payments/vnpay/callback") {
                // The server returns JSON. Read it from the document body.
                webView.evaluateJavaScript("document.body.innerText") { [weak self] result, error in
                    guard let self = self, let jsonString = result as? String, let data = jsonString.data(using: .utf8) else {
                        self?.parent.onComplete(.failure("Failed to parse payment response"))
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            let success = json["success"] as? Bool ?? false
                            let message = json["message"] as? String ?? "Unknown error"
                            let orderId = json["orderId"] as? String ?? ""
                            
                            if success {
                                self.parent.onComplete(.success(orderId))
                            } else {
                                self.parent.onComplete(.failure(message))
                            }
                        } else {
                            self.parent.onComplete(.failure("Invalid response format"))
                        }
                    } catch {
                        self.parent.onComplete(.failure("Failed to decode response: \(error.localizedDescription)"))
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // Optional: Handle loading failures
            // parent.onComplete(.failure(error.localizedDescription))
        }
    }
}
