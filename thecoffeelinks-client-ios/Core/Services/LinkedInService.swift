import Foundation
import AuthenticationServices
import UIKit

enum LinkedInError: Error {
    case invalidConfig
    case authCanceled
    case invalidResponse
    case tokenExchangeFailed(String)
}

@MainActor
class LinkedInService: NSObject {
    private var webAuthSession: ASWebAuthenticationSession?
    
    // Configuration Keys
    private let kClientId = "LINKEDIN_CLIENT_ID"
    private let kClientSecret = "LINKEDIN_CLIENT_SECRET"
    private let kRedirectUri = "LINKEDIN_REDIRECT_URI"
    
    func login() async throws -> String {
        // 1. Get Config
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let clientId = config[kClientId] as? String,
              let redirectUri = config[kRedirectUri] as? String,
              !clientId.contains("YOUR_LINKEDIN") else {
            throw LinkedInError.invalidConfig
        }
        
        // 2. Prepare Auth URL
        var components = URLComponents(string: "https://www.linkedin.com/oauth/v2/authorization")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: "openid profile email"),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        
        guard let authURL = components.url else {
            throw LinkedInError.invalidConfig
        }
        
        // 3. Perform Web Auth
        let code: String = try await withCheckedThrowingContinuation { continuation in
            webAuthSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "thecoffeelinks"
            ) { callbackURL, error in
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: LinkedInError.authCanceled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems,
                      let code = queryItems.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: LinkedInError.invalidResponse)
                    return
                }
                
                continuation.resume(returning: code)
            }
            
            webAuthSession?.presentationContextProvider = self
            webAuthSession?.start()
        }
        
        return code
    }
}

extension LinkedInService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the key window
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
