//
//  DigitalCardView.swift
//  thecoffeelinks-native-swift
//
//  QR Membership Card per Blueprint P-006
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct DigitalCardView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Mock user data (will be moved to ProfileViewModel)
    private let userName = "Member"
    private let memberId = "000000"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.forestCanopy, Color.forestCanopy.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Card
                    cardView
                    
                    // Actions
                    actionButtons
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                        .tint(.white)
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.6))
                                .font(.system(size: 28))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Card View
    
    private var cardView: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("THE COFFEE LINKS")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(Color.sunRay)
                    
                    Text("Member Card")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                // Logo placeholder
                Circle()
                    .fill(Color.sunRay)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text("CL")
                            .font(.headline.bold())
                            .foregroundStyle(Color.forestCanopy)
                    }
            }
            
            Divider().background(.white.opacity(0.2))
            
            // QR Code
            qrCode
                .frame(width: 180, height: 180)
                .background(Color.white)
                .cornerRadius(16)
            
            // Member Info
            VStack(spacing: 4) {
                Text(userName)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("Gold Member")
                    .font(.caption)
                    .foregroundStyle(Color.sunRay)
                
                Text("ID: \(memberId)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            // Points
            HStack(spacing: 20) {
                statItem("2,450", label: "Points")
                Divider().frame(height: 30).background(.white.opacity(0.2))
                statItem("47", label: "Orders")
                Divider().frame(height: 30).background(.white.opacity(0.2))
                statItem("12", label: "Rewards")
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.3))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
        )
    }
    
    private func statItem(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    // MARK: - QR Code
    
    private var qrCode: some View {
        Group {
            if let uiImage = generateQRCode(from: memberId) {
                Image(uiImage: uiImage)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color.neutral200)
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scaleX = 200 / outputImage.extent.size.width
        let scaleY = 200 / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            actionButton(icon: "square.and.arrow.up", title: "Share") {
                // Share action
            }
            
            actionButton(icon: "doc.on.doc", title: "Copy ID") {
                UIPasteboard.general.string = memberId
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            
            actionButton(icon: "arrow.down.to.line", title: "Save") {
                // Save to wallet
            }
        }
    }
    
    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    DigitalCardView()
}
