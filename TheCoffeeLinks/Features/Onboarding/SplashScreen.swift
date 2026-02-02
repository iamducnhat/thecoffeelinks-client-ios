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
            Color(red: 0.7215686275, green: 0.6039215686, blue: 0.3450980392).ignoresSafeArea()
            
            VStack(spacing: AppLayout.spacingXL) {
                // Brand Mark — use full-color logo (use `logo` asset)
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .accessibilityHidden(true)
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
