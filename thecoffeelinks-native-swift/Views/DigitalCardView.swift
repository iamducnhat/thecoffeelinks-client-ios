//
//  DigitalCardView.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design / Boarding Pass Style
//  Aligned with design goals: Calm, authoritative, editorial.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct DigitalCardView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            // Main Content
            ScrollView {
                DigitalCredentialContent(
                    memberId: authViewModel.currentUser?.shortId ?? "******",
                     userName: authViewModel.currentUser?.displayName ?? "Member",
                     tier: authViewModel.currentUser?.membershipTier.displayName ?? "Member",
                     points: authViewModel.currentUser?.points ?? 0,
                     vouchersCount: profileViewModel.vouchers.count,
                     ordersCount: profileViewModel.orderCount,
                     onRefresh: {
                         profileViewModel.loadProfile()
                     }
                )
                .padding(AppLayout.spacing)
            }
            
            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textMuted)
                            .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                    }
                }
                .padding(.horizontal, AppLayout.spacing)
                Spacer()
            }
        }
    }
}

// MARK: - Reusable Content View

struct DigitalCredentialContent: View {
    let memberId: String
    let userName: String
    let tier: String
    let points: Int
    let vouchersCount: Int
    let ordersCount: Int
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: AppLayout.spacingXL) {
            
            // 1. Context Header
            VStack(spacing: 4) {
                Text("THE COFFEE LINKS")
                    .font(AppFont.sectionHeader) // Serif
                    .foregroundColor(Color.textInk)
                
                Text("DIGITAL MEMBER")
                    .font(AppFont.uiMicro)
                    .textCase(.uppercase)
                    .kerning(1.5)
                    .foregroundColor(Color.textMuted)
            }
            .padding(.top, AppLayout.spacingLarge)
            
            // 2. QR Code (Visual Focus)
            VStack {
                QRCodeView(string: memberId)
                    .frame(width: 240, height: 240) // Larger size
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                    // Minimal container
                    .padding(AppLayout.spacing)
                    .background(Color.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
            
            // 3. User Identity Block
            VStack(spacing: 4) {
                Text(userName)
                    .font(AppFont.displayTitle) // Serif, Semibold
                    .foregroundColor(Color.textInk)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 8) {
                    Text(tier)
                    Text("·")
                    Text(memberId)
                        .font(AppFont.monoBody)
                }
                .font(AppFont.body)
                .foregroundColor(Color.primaryEspresso)
            }
            
            DividerLine()
            
            // 4. Stats Section (Receipt-style vertical list)
            VStack(spacing: AppLayout.spacing) {
                StatRow(label: "POINTS", value: "\(points)")
                StatRow(label: "VOUCHERS", value: "\(vouchersCount)")
                StatRow(label: "ORDERS", value: "\(ordersCount)")
            }
            .padding(.horizontal, AppLayout.spacingLarge)
            
            DividerLine()
            
            // 5. Actions
            HStack(spacing: AppLayout.spacingXL) {
                ActionButton(icon: "doc.on.doc", title: "Copy ID") {
                    UIPasteboard.general.string = memberId
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
                
                ActionButton(icon: "arrow.clockwise", title: "Refresh") {
                    onRefresh()
                }
            }
            .padding(.bottom, AppLayout.spacing)
            
        }
    }
}

// MARK: - Subviews

struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.textMuted.opacity(0.2))
            .frame(height: 1)
            .padding(.horizontal, AppLayout.spacingLarge)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFont.sectionHeader) // Serif
                .foregroundColor(Color.textInk)
                .font(.system(size: 14)) // Override size slightly for list? 
                // Request: "Label on left... Serif for titles and labels"
                // Let's use sectionHeader but maybe smaller scale if needed? 
                // sectionHeader is title3 (.medium).
            
            Spacer()
            
            // Dotted leader simulation? Or just space.
            // Request: "Points ...... Value" (Dotted usually implying leader)
            // But "Vertical list... Label on left, value on right"
            
            Text(value)
                .font(AppFont.monoHeadline) // Monospaced for values
                .foregroundColor(Color.textInk)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(AppFont.uiButton) // Or Mono?
            // Request: "Inline buttons or text buttons... No card background"
            .foregroundColor(Color.primaryEspresso)
        }
    }
}

struct QRCodeView: View {
    let string: String
    
    var body: some View {
        if let uiImage = generateQRCode(from: string) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
        } else {
            Rectangle()
                .fill(Color.surfaceCard)
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H" // High for better scanning
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

//#Preview {
//    DigitalCardView()
//        .environmentObject(AuthViewModel(authRepository: <#AuthRepository#>))
//}
