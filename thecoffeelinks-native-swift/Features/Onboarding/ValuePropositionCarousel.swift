//
//  ValuePropositionCarousel.swift
//  thecoffeelinks-native-swift
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
            image: "cup.and.saucer"
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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Indicator
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(currentPage >= index ? Color.primaryEspresso : Color.border)
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
                        .fill(Color.backgroundPaper)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: slides[currentPage].image)
                                .font(.system(size: 32))
                                .foregroundStyle(Color.primaryEspresso)
                        )
                        .overlay(
                            Circle().stroke(Color.border, lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text(slides[currentPage].title)
                            .font(AppFont.displayTitle)
                            .foregroundStyle(Color.textInk)
                            .lineLimit(2)
                        
                        Text(slides[currentPage].subtitle)
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Navigation
                HStack {
                    if currentPage < slides.count - 1 {
                        Button("Skip") {
                            onFinished()
                        }
                        .font(AppFont.monoBody)
                        .foregroundColor(Color.textMuted)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Next")
                                .font(AppFont.monoBody)
                                .foregroundColor(Color.primaryEspresso)
                        }
                    } else {
                        Button {
                            onFinished()
                        } label: {
                            Text("Get Started")
                                .font(AppFont.monoCTA)
                                .foregroundColor(Color.backgroundPaper)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
    }
}
