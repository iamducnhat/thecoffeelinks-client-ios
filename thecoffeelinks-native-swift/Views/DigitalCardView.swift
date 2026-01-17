//
//  DigitalCardView.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct DigitalCardView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let userName = "Member"
    private let memberId = "000000"
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textInk)
                            .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                    }
                    
                    Spacer()
                    
                    Text("Member Card")
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Color.clear.frame(width: AppLayout.touchTarget, height: AppLayout.touchTarget)
                }
                .padding(.horizontal, AppLayout.spacing)
                .padding(.top, AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                    .padding(.top, AppLayout.spacing)
                
                ScrollView {
                    VStack(spacing: AppLayout.spacingXL) {
                        // Card
                        VStack(spacing: AppLayout.spacing) {
                            // Brand
                            VStack(spacing: 4) {
                                Text("THE COFFEE LINKS")
                                    .font(AppFont.uiMicro)
                                    .kerning(2)
                                    .foregroundColor(Color.primaryEspresso)
                                
                                Text("Digital Member Card")
                                    .font(AppFont.sectionHeader)
                                    .foregroundColor(Color.textInk)
                            }
                            
                            Color.secondary.frame(height: 1)
                            
                            // QR Code
                            QRCodeView(string: memberId)
                                .frame(width: 160, height: 160)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.border, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                            
                            // Member Info
                            VStack(spacing: 4) {
                                Text(userName)
                                    .font(AppFont.headline)
                                    .foregroundColor(Color.textInk)
                                
                                Text("Gold Member")
                                    .font(AppFont.uiCaption)
                                    .foregroundColor(Color.primaryEspresso)
                                
                                Text("ID: \(memberId)")
                                    .font(AppFont.monoBody)
                                    .foregroundColor(Color.textMuted)
                            }
                            
                            Color.secondary.frame(height: 1)
                            
                            // Stats
                            HStack(spacing: AppLayout.spacing) {
                                StatItem(value: "2,450", label: "Points")
                                StatItem(value: "47", label: "Orders")
                                StatItem(value: "12", label: "Rewards")
                            }
                        }
                        .padding(AppLayout.spacing)
                        .background(Color.surfaceCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        
                        // Action Buttons
                        HStack(spacing: AppLayout.spacing) {
                            CardActionButton(icon: "square.and.arrow.up", title: "Share") { }
                            
                            CardActionButton(icon: "doc.on.doc", title: "Copy ID") {
                                UIPasteboard.general.string = memberId
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                            
                            CardActionButton(icon: "arrow.down.to.line", title: "Save") { }
                        }
                    }
                    .padding(AppLayout.spacing)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFont.monoBody)
                .foregroundColor(Color.textInk)
            Text(label)
                .font(AppFont.uiMicro)
                .foregroundColor(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - QR Code

struct QRCodeView: View {
    let string: String
    
    var body: some View {
        if let uiImage = generateQRCode(from: string) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .padding(AppLayout.spacingMedium)
        } else {
            Rectangle()
                .fill(Color.surfaceCard)
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Action Button

struct CardActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(AppFont.uiMicro)
            }
            .foregroundColor(Color.textInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppLayout.spacing)
            .background(Color.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        }
    }
}

#Preview {
    DigitalCardView()
}
