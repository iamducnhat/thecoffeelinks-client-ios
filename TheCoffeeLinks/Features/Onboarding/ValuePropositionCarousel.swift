//
//  ValuePropositionCarousel.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct ValuePropositionCarousel: View {
    let onFinished: () -> Void
    @State private var currentPage = 0
    
    struct Slide {
        let title: String
        let subtitle: String
        let image: String
    }
    
    let slides = [
        Slide(
            title: "Discover\nGreat Coffee",
            subtitle: "Find the finest local roasters and explore new flavors from your favorite cafés.",
            image: "coffee"
        ),
        Slide(
            title: "Skip\nThe Line",
            subtitle: "Order ahead and pick up when it's ready. Your perfect coffee, waiting for you.",
            image: "clock"
        ),
        Slide(
            title: "Connect\n& Share",
            subtitle: "Share your favorites, send gift cards, and discover where your friends are getting their coffee.",
            image: "heart"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Indicator
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(currentPage >= index ? Color.accentPrimary : Color.border)
                            .frame(height: 2)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Content
                VStack(alignment: .leading, spacing: AppLayout.spacingXL) {
                    // Image Placeholder (Icon)
                    Circle()
                        .fill(Color.bgPrimary)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(slides[currentPage].image)
                                .font(.system(size: 32))
                                .foregroundStyle(Color.accentPrimary)
                        )
                        .overlay(
                            Circle().strokeBorder(Color.border, lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text(slides[currentPage].title)
                            .font(AppFont.displayTitle)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(2)
                        
                        Text(slides[currentPage].subtitle)
                            .font(AppFont.body)
                            .foregroundStyle(Color.textSecondary)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Navigation
                HStack {
                    if currentPage < slides.count - 1 {
                        Button(String(localized: "common_skip")) {
                            onFinished()
                        }
                        .font(AppFont.monoBody)
                        .foregroundColor(Color.textSecondary)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text(String(localized: "common_next"))
                                .font(AppFont.monoBody)
                                .foregroundColor(Color.accentPrimary)
                        }
                    } else {
                        Button {
                            onFinished()
                        } label: {
                            Text(String(localized: "common_get_started"))
                                .font(AppFont.monoCTA)
                                .foregroundColor(Color.bgPrimary)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color.accentPrimary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
    }
}
