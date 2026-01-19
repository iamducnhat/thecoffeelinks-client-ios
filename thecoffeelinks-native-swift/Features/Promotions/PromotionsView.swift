//
//  PromotionsView.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct PromotionsView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showLogin = false
    @State private var scrollOffset = CGFloat.zero
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Header
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text("Promotions")
                            .font(AppFont.displayTitle)
                            .foregroundColor(Color.textInk)
                            .padding(.top, AppLayout.spacing)
                        
                        Color.secondary.frame(height: 1)
                    }
                    .padding(.horizontal, AppLayout.spacing)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    VStack(spacing: AppLayout.spacingXL) {
                        if authViewModel.isAuthenticated {
                            memberCard
                        } else {
                            guestState
                        }
                    }
                    .padding(AppLayout.spacing)
                    .padding(.bottom, 100)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
        .onAppear {
            if authViewModel.isAuthenticated {
                profileViewModel.loadProfile()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                showLogin = false
                profileViewModel.loadProfile()
            }
        }
    }
    
    private var memberCard: some View {
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
            QRCodeView(string: profileViewModel.userProfile?.id ?? "000000")
                .frame(width: 200, height: 200)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(Color.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            
            // Member Info
            VStack(spacing: 4) {
                Text(profileViewModel.userProfile?.fullName ?? "Member")
                    .font(AppFont.headline)
                    .foregroundColor(Color.textInk)
                
                Text(profileViewModel.userProfile?.membershipTier.displayName ?? "Member")
                    .font(AppFont.uiCaption)
                    .foregroundColor(Color.primaryEspresso)
                
                Text("ID: \(profileViewModel.userProfile?.id ?? "000000")")
                    .font(AppFont.monoBody)
                    .foregroundColor(Color.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Color.secondary.frame(height: 1)
            
            // Stats
            HStack(spacing: AppLayout.spacing) {
                StatItem(value: "\(profileViewModel.userProfile?.points ?? 0)", label: "Points")
                StatItem(value: "\(profileViewModel.vouchers.count)", label: "Vouchers")
            }
            
            Color.secondary.frame(height: 1)
            
            // Actions
             HStack(spacing: AppLayout.spacing) {
                 CardActionButton(icon: "doc.on.doc", title: "Copy ID") {
                     UIPasteboard.general.string = profileViewModel.userProfile?.id ?? ""
                     let generator = UIImpactFeedbackGenerator(style: .medium)
                     generator.impactOccurred()
                 }
                 
                 CardActionButton(icon: "arrow.clockwise", title: "Refresh") {
                     profileViewModel.loadProfile()
                 }
             }
        }
        .padding(AppLayout.spacing)
        .background(Color.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
    }
    
    private var guestState: some View {
        VStack(spacing: AppLayout.spacingXL) {
            Image(systemName: "ticket")
                .font(.system(size: 48))
                .foregroundStyle(Color.textMuted)
            
            Text("Sign in to access promotions")
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
            
            Text("Join our membership program to earn points, redeem vouchers, and get exclusive offers.")
                .font(AppFont.body)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
            
            Button {
                showLogin = true
            } label: {
                Text("Sign in or Join")
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.backgroundPaper)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
        }
        .padding(AppLayout.spacing)
        .background(Color.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
    }
    
    // Helper function for QR generation
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

// MARK: - Private Components

// Reuse helper views by nesting them to avoid conflict with DigitalCardView
extension PromotionsView {
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
}
