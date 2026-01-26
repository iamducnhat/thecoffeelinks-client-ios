import SwiftUI
import UIKit
import CoreImage

/// Pure rendering view for QR Codes.
/// Strictly follows backend payload.
/// No validation logic here.
struct QRRenderView: View {
    let payload: String
    
    var body: some View {
        VStack {
            if let qrImage = generateQRCode(from: payload) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            } else {
                Image("xmark.circle")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .foregroundColor(.red)
            }
            
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        
        filter.setValue(Data(string.utf8), forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            // Scale up via transform for sharpness
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
}

// Preview Provider
struct QRRenderView_Previews: PreviewProvider {
    static var previews: some View {
        // Example Payload: v:VCH9821|u:8F3K2Q|s:Qx9L2
        QRRenderView(payload: "v:VCH9821|u:8F3K2Q|s:Qx9L2")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
