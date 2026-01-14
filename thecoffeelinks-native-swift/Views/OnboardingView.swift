//
//  OnboardingView.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-14.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted: Bool = false
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            title: "Order & Pay in Seconds",
            description: "Skip the line. Order your favorite brew with custom options and pay instantly.",
            imageName: "cup.and.saucer.fill", // Placeholder for Latte Art
            color: Color.forestCanopy
        ),
        OnboardingPage(
            title: "Reserve Your Success Space",
            description: "Find your perfect spot. Book a quiet corner or a meeting room equipped for professionals.",
            imageName: "chair.lounge.fill", // Placeholder for Space
            color: Color.forestFloor
        ),
        OnboardingPage(
            title: "Network with Professionals",
            description: "Connect for Success. Discover like-minded people and grow your career over coffee.",
            imageName: "person.2.wave.2.fill", // Placeholder for Handshake
            color: Color.sunRay
        )
    ]
    
    var body: some View {
        ZStack {
            Color.morningFog.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(.brandSans(16))
                        .foregroundStyle(Color.neutral600)
                        .padding()
                    } else {
                        Spacer().frame(height: 52) // Balance layout
                    }
                }
                
                // Carousel
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Indicators & Controls
                VStack(spacing: 32) {
                    // Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.forestCanopy : Color.neutral300)
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    // Action Button
                    LiquidGlassPrimaryButton(
                        currentPage == pages.count - 1 ? "Get Started" : "Next",
                        icon: currentPage == pages.count - 1 ? "arrow.right" : nil,
                        tint: .forestCanopy
                    ) {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
            }
        }
        .transition(.opacity)
    }
    
    private func completeOnboarding() {
        withAnimation {
            isOnboardingCompleted = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Image Area
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 280, height: 280)
                
                Image(systemName: page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(page.color)
            }
            .padding(.bottom, 24)
            
            // Text Area
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.brandSerif(28))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.forestCanopy)
                
                Text(page.description)
                    .font(.brandSans(16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.neutral600)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
