//
//  SplashScreen.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct SplashScreen: View {
    @Binding var isActive: Bool
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.95
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: AppLayout.spacingXL) {
                // Brand Mark
                Image("coffee")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Color.accentPrimary)
                
                VStack(spacing: AppLayout.spacing) {
                    Text(String(localized: "app_name"))
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text(String(localized: "splash_tagline"))
                        .font(AppFont.body)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .opacity(opacity)
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                opacity = 1
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    // This expects `isActive` to trigger navigation in the parent view
                    isActive = true
                }
            }
        }
    }
}
