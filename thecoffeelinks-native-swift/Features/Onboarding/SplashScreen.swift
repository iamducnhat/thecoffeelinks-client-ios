//
//  SplashScreen.swift
//  thecoffeelinks-native-swift
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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: AppLayout.spacingXL) {
                // Brand Mark
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Color.primaryEspresso)
                
                VStack(spacing: AppLayout.spacing) {
                    Text("The Coffee Links")
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textInk)
                    
                    Text("Your daily ritual, perfected")
                        .font(AppFont.body)
                        .foregroundStyle(Color.textMuted)
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
