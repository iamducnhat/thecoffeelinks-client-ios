//
//  AsyncImageHelpers.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-13.
//

import SwiftUI

/// Custom AsyncImage view with consistent loading and error states
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    var body: some View {
        if let urlString = url, !urlString.isEmpty, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    content(image)
                case .failure(_):
                    placeholder()
                case .empty:
                    ZStack {
                        placeholder()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    }
                @unknown default:
                    placeholder()
                }
            }
        } else {
            placeholder()
        }
    }
}

// MARK: - Convenient View Modifiers
extension View {
    /// Load image from Supabase storage with fallback
    func supImageLoader(
        url: String?,
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat = 12,
        fallbackIcon: String = "photo"
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.coffeeRich.opacity(0.05))
                .frame(width: width, height: height)
            
            if let urlString = url, !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: height)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    case .failure(_):
                        Image(systemName: fallbackIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: width * 0.4, height: height * 0.4)
                            .foregroundStyle(Color.coffeeRich.opacity(0.3))
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    @unknown default:
                        Image(systemName: fallbackIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: width * 0.4, height: height * 0.4)
                            .foregroundStyle(Color.coffeeRich.opacity(0.3))
                    }
                }
            } else {
                Image(systemName: fallbackIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width * 0.4, height: height * 0.4)
                    .foregroundStyle(Color.coffeeRich.opacity(0.3))
            }
        }
    }
}

// MARK: - Reusable Image Components
struct ProductImageView: View {
    let imageUrl: String?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        CachedAsyncImage(url: imageUrl) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
        } placeholder: {
            ZStack {
                Color.coffeeRich.opacity(0.05)
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width * 0.4)
                    .foregroundStyle(Color.coffeeRich.opacity(0.2))
            }
            .frame(width: width, height: height)
        }
    }
}

struct EventImageView: View {
    let imageUrl: String?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        CachedAsyncImage(url: imageUrl) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
        } placeholder: {
            ZStack {
                Color.coffeeRich.opacity(0.05)
                Image(systemName: "calendar")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width * 0.4)
                    .foregroundStyle(Color.coffeeRich.opacity(0.3))
            }
            .frame(width: width, height: height)
        }
    }
}

struct StoreImageView: View {
    let imageUrl: String?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        CachedAsyncImage(url: imageUrl) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
        } placeholder: {
            ZStack {
                Color.coffeeRich.opacity(0.1)
                Image(systemName: "building.2.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width * 0.4)
                    .foregroundStyle(Color.coffeeRich.opacity(0.3))
            }
            .frame(width: width, height: height)
        }
    }
}

struct VoucherImageView: View {
    let imageUrl: String?
    let isGold: Bool
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isGold ? Color.gold.opacity(0.2) : Color.sage.opacity(0.2))
                .frame(width: size, height: size)
            
            CachedAsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } placeholder: {
                Image(systemName: isGold ? "star.fill" : "ticket.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.5)
                    .foregroundStyle(isGold ? Color.gold : Color.sage)
            }
        }
    }
}
