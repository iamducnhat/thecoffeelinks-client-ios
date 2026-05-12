import SwiftUI
import UIKit
import CoreImage

/// Pure rendering view for Code 128 barcodes.
/// Strictly follows backend payload.
/// No validation logic here.
struct BarcodeRenderView: View {
    private static let targetAspectRatio: CGFloat = 4.0
    private static let targetWidth: CGFloat = 720.0
    private static let quietSpace: CGFloat = 0.0

    let payload: String

    var body: some View {
        Group {
            if let barcodeImage = generateBarcode(from: payload) {
                Image(uiImage: barcodeImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("Barcode")
            } else {
                Image(systemName: "xmark.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.red)
            }
        }
    }

    private func generateBarcode(from string: String) -> UIImage? {
        let context = CIContext()
        guard let filter = CIFilter(name: "CICode128BarcodeGenerator") else { return nil }

        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue(Self.quietSpace, forKey: "inputQuietSpace")

        guard let outputImage = filter.outputImage else { return nil }

        let outputWidth = max(outputImage.extent.width, 1.0)
        let outputHeight = max(outputImage.extent.height, 1.0)
        let targetHeight = Self.targetWidth / Self.targetAspectRatio
        let scaleX = max(1.0, Self.targetWidth / outputWidth)
        let scaleY = max(1.0, targetHeight / outputHeight)
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

// Preview Provider
struct BarcodeRenderView_Previews: PreviewProvider {
    static var previews: some View {
        BarcodeRenderView(payload: "v1|eyJ0IjoidiIsInUiOiI4RjNLMlEiLCJ2IjoiNTUwZTg0MDAiLCJlIjoxNzc3OTY3OTk5LCJuIjoiYTFiMmMzZDRlNWY2In0=|f7ea1b66c9a1d1d8")
            .frame(width: 320, height: 80)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
