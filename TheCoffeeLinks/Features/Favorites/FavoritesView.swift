//
//  FavoritesView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import Combine
import CachedAsyncImage // CHANGED

struct FavoritesView: View {
    @StateObject private var viewModel: FavoritesViewModel
    @EnvironmentObject private var cartViewModel: CartViewModel
    @State private var showingProductDetail: Product?
    @State private var scrollOffset = CGFloat.zero
    @Environment(\.dismiss) var dismiss
    
    init(favoritesRepository: FavoritesRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: FavoritesViewModel(favoritesRepository: favoritesRepository))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            
            // Fixed Navigation Header
            HStack(alignment: .center, spacing: AppLayout.spacing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(AppFont.navIcon)
                        .foregroundStyle(Color.textPrimary)
                        .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                        .background {
                            Capsule()
                                .fill(Color.bgPrimary)
                        }
                        .overlay {
                            Capsule()
                                .strokeBorder(Color.textPrimary, lineWidth: min(66.6, max(scrollOffset, 0.0)) / 66.6)
                                .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                        }
                }
                
                Text("favorites_title")
                    .font(AppFont.displayTitle)
                    .lineLimit(1)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hidden()
            }
            .frame(minHeight: AppLayout.touchTarget)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, AppLayout.spacing)
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Navigation Header (Scrollable)
                    HStack(alignment: .center, spacing: AppLayout.spacing) {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textPrimary)
                            .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                            .hidden()
                        
                        Text("favorites_title")
                            .font(AppFont.displayTitle)
                            .lineLimit(1)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: AppLayout.touchTarget)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, AppLayout.spacing)
                    .overlay(alignment: .bottom) {
                        Color.secondary.frame(height: 1, alignment: .top)
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    if viewModel.isLoading {
                        ReceiptLoadingLog()
                            .padding(AppLayout.spacing)
                    } else if viewModel.favorites.isEmpty {
                        VStack(spacing: AppLayout.spacing) {
                            Text("favorites_empty_title")
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            Text("favorites_empty_message")
                                .font(AppFont.body)
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(60)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.border, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                        )
                        .padding(AppLayout.spacing)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.favorites.enumerated()), id: \.element.id) { index, favorite in
                                FavoriteItemRow(favorite: favorite, showDivider: index < viewModel.favorites.count - 1) {
                                    showingProductDetail = favorite.product
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.removeFavorite(id: favorite.id) }
                                    } label: {
                                        Label {
                            Text(String(localized: "common_delete"))
                        } icon: {
                            Image("trash")
                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        .padding(.bottom, 40)
                    }
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
            }
            .zIndex(-Double.infinity)
        }
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .fullScreenCover(item: $showingProductDetail) { product in
            ProductDetailSheet(product: product)
        }
    }
}

// MARK: - Favorite Item Row

struct FavoriteItemRow: View {
    let favorite: FavoriteItem
    var showDivider: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: AppLayout.spacing) {
                    // Image
                    // CHANGED: Using CachedAsyncImage
                    CachedAsyncImage(url: URL(string: favorite.product.displayImageUrl ?? "")) { phase in // CHANGED
                        switch phase { // CHANGED
                        case .empty: // CHANGED
                            Rectangle() // CHANGED
                                .fill(Color.surfacePrimary) // CHANGED
                                .overlay { // CHANGED
                                    ProgressView() // CHANGED
                                        .tint(Color.accentPrimary) // CHANGED
                                } // CHANGED
                        case .success(let image): // CHANGED
                            image // CHANGED
                                .resizable() // CHANGED
                                .aspectRatio(contentMode: .fill) // CHANGED
                        case .failure: // CHANGED
                            Rectangle() // CHANGED
                                .fill(Color.surfacePrimary) // CHANGED
                                .overlay { // CHANGED
                                    Text(String(favorite.product.name.prefix(1))) // CHANGED
                                        .font(AppFont.sectionHeader) // CHANGED
                                        .foregroundStyle(Color.textSecondary) // CHANGED
                                } // CHANGED
                        @unknown default: // CHANGED
                            EmptyView() // CHANGED
                        } // CHANGED
                    } // CHANGED
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
                        Capsule()
                            .strokeBorder(Color.border, lineWidth: 1)
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(favorite.displayName)
                            .font(AppFont.body)
                            .lineLimit(2)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text(favorite.customization.displayText)
                            .font(AppFont.uiCaption)
                            .foregroundStyle(Color.textSecondary)
                        
                        HStack(spacing: 4) {
                            Text(favorite.product.priceRange)
                                .font(AppFont.monoBody)
                                .foregroundStyle(Color.accentPrimary)
                            
                            if favorite.orderCount > 0 {
                                Text(String(localized: "favorite_ordered_count_format \(favorite.orderCount)"))
                                    .font(AppFont.uiMicro)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.vertical, AppLayout.spacing)
                
                if showDivider {
                    Color.secondary.frame(height: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
