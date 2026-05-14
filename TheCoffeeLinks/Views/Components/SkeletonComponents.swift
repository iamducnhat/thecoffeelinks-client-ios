//
//  SkeletonComponents.swift
//  thecoffeelinks-client-ios
//
//  Skeleton loading components per Blueprint - perceived performance
//

import SwiftUI

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.5),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Shapes

struct SkeletonRectangle: View {
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 4
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(BaseViewColor.surface)
            .frame(height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var size: CGFloat = 40
    
    var body: some View {
        Circle()
            .fill(BaseViewColor.surface)
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - Product Card Skeleton

struct LegacyProductCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(BaseViewColor.surface)
                .frame(width: 72, height: 72)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 8) {
                // Title
                SkeletonRectangle(height: 14)
                    .frame(width: 120)
                
                // Description
                SkeletonRectangle(height: 10)
                    .frame(width: 180)
                
                // Price
                SkeletonRectangle(height: 14)
                    .frame(width: 60)
            }
            
            Spacer()
            
            // Add button
            RoundedRectangle(cornerRadius: 8)
                .fill(BaseViewColor.surface)
                .frame(width: 32, height: 32)
                .shimmer()
        }
        .padding(14)
        .background(BaseViewColor.surface)
    }
}

// MARK: - Menu Skeleton (for OrderTabView)

struct MenuSkeletonView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Store selector skeleton
            HStack {
                SkeletonCircle(size: 24)
                SkeletonRectangle(height: 14)
                    .frame(width: 120)
                Spacer()
            }
            .padding()
            .background(BaseViewColor.surface)
            
            // Category tabs skeleton
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 20)
                            .fill(BaseViewColor.surface)
                            .frame(width: 80, height: 32)
                            .shimmer()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(BaseViewColor.surface)
            
            // Products skeleton
            VStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { _ in
                    LegacyProductCardSkeleton()
                    Divider().padding(.leading, 88)
                }
            }
            .background(BaseViewColor.surface)
            .cornerRadius(16)
            .padding()
        }
    }
}

// MARK: - Home Skeleton

struct HomeSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header skeleton
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonRectangle(height: 24)
                            .frame(width: 150)
                        SkeletonRectangle(height: 14)
                            .frame(width: 200)
                    }
                    Spacer()
                    SkeletonCircle(size: 44)
                }
                .padding(.horizontal)
                
                // Quick Order skeleton
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonRectangle(height: 16)
                        .frame(width: 100)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(BaseViewColor.surface)
                                    .frame(width: 100, height: 150)
                                    .shimmer()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Highlights skeleton
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonRectangle(height: 16)
                        .frame(width: 80)
                        .padding(.horizontal)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(BaseViewColor.surface)
                        .frame(height: 160)
                        .padding(.horizontal)
                        .shimmer()
                }
                
                // Products skeleton
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { _ in
                        LegacyProductCardSkeleton()
                    }
                }
                .background(BaseViewColor.surface)
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(BaseViewColor.background)
    }
}

// MARK: - Store Card Skeleton

struct StoreCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // Image
            RoundedRectangle(cornerRadius: 12)
                .fill(BaseViewColor.surface)
                .frame(width: 80, height: 80)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 6) {
                SkeletonRectangle(height: 16)
                    .frame(width: 140)
                SkeletonRectangle(height: 12)
                    .frame(width: 200)
                
                HStack(spacing: 8) {
                    SkeletonRectangle(height: 10)
                        .frame(width: 50)
                    SkeletonRectangle(height: 10)
                        .frame(width: 60)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(BaseViewColor.surface)
        .cornerRadius(16)
    }
}

// MARK: - Profile Skeleton

struct ProfileSkeletonView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Avatar
            SkeletonCircle(size: 80)
            
            // Name
            SkeletonRectangle(height: 24)
                .frame(width: 150)
            
            // Title
            SkeletonRectangle(height: 14)
                .frame(width: 100)
            
            // Badges
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(BaseViewColor.surface)
                        .frame(width: 100, height: 24)
                        .shimmer()
                }
            }
            
            // Menu items
            VStack(spacing: 1) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        SkeletonCircle(size: 28)
                        SkeletonRectangle(height: 16)
                            .frame(width: 120)
                        Spacer()
                    }
                    .padding()
                    .background(BaseViewColor.surface)
                }
            }
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.top, 40)
    }
}

// MARK: - Order History Skeleton

struct OrderHistorySkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SkeletonRectangle(height: 14)
                            .frame(width: 80)
                        Spacer()
                        SkeletonRectangle(height: 12)
                            .frame(width: 60)
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(0..<2, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(BaseViewColor.surface)
                                .frame(width: 50, height: 50)
                                .shimmer()
                        }
                        Spacer()
                        SkeletonRectangle(height: 16)
                            .frame(width: 80)
                    }
                }
                .padding()
                .background(BaseViewColor.surface)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    ScrollView(.vertical) {
        VStack(spacing: 40) {
            Text("Product Card").font(.headline)
            LegacyProductCardSkeleton()
            
            Text("Menu View").font(.headline)
            MenuSkeletonView()
                .frame(height: 400)
        }
    }
    .background(BaseViewColor.background)
}
