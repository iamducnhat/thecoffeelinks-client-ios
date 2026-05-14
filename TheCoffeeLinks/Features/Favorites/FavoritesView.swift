//
//  FavoritesView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
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
            BaseViewColor.background.ignoresSafeArea()
            
            // Fixed Navigation Header
            HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(BaseViewFont.navIcon)
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .frame(minWidth: BaseViewLayout.touchTarget, minHeight: BaseViewLayout.touchTarget)
                        .background {
                            Circle()
                                .fill(BaseViewColor.background)
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(BaseViewColor.textPrimary, lineWidth: 1)
                                .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                        }
                }
                
                Text("favorites_title")
                    .font(BaseViewFont.displayTitle)
                    .lineLimit(1)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hidden()
            }
            .frame(minHeight: BaseViewLayout.touchTarget)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, BaseViewLayout.spacing)
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Navigation Header (Scrollable)
                    HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                        Image(systemName: "xmark")
                            .font(BaseViewFont.navIcon)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .frame(minWidth: BaseViewLayout.touchTarget, minHeight: BaseViewLayout.touchTarget)
                            .hidden()
                        
                        Text("favorites_title")
                            .font(BaseViewFont.displayTitle)
                            .lineLimit(1)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: BaseViewLayout.touchTarget)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, BaseViewLayout.spacing)
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
                            .padding(BaseViewLayout.spacing)
                    } else if viewModel.favorites.isEmpty {
                        VStack(spacing: BaseViewLayout.spacing) {
                            Text("favorites_empty_title")
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            Text("favorites_empty_message")
                                .font(BaseViewFont.body)
                                .foregroundStyle(BaseViewColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(60)
                        .overlay(
                            Capsule()
                                .strokeBorder(BaseViewColor.border, style: StrokeStyle(lineWidth: 1, dash: BaseViewLayout.dashedPattern))
                        )
                        .padding(BaseViewLayout.spacing)
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
                        .padding(.horizontal, BaseViewLayout.spacing)
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
                HStack(spacing: BaseViewLayout.spacing) {
                    AppRemoteImage(
                        url: URL(string: favorite.product.displayImageUrl ?? ""),
                        width: 70,
                        height: 70,
                        cornerRadius: BaseViewLayout.radiusMedium,
                        backgroundColor: BaseViewColor.surface,
                        borderColor: BaseViewColor.border,
                        showsProgress: true,
                        placeholderIcon: nil,
                        placeholderText: String(favorite.product.name.prefix(1))
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(favorite.displayName)
                            .font(BaseViewFont.body)
                            .lineLimit(2)
                            .foregroundStyle(BaseViewColor.textPrimary)
                        
                        Text(favorite.customization.displayText)
                            .font(BaseViewFont.uiCaption)
                            .foregroundStyle(BaseViewColor.textSecondary)
                        
                        HStack(spacing: 4) {
                            Text(favorite.product.priceRange)
                                .font(BaseViewFont.monoBody)
                                .foregroundStyle(BaseViewColor.accent)
                            
                            if favorite.orderCount > 0 {
                                Text(String(localized: "favorite_ordered_count_format \(favorite.orderCount)"))
                                    .font(BaseViewFont.uiMicro)
                                    .foregroundStyle(BaseViewColor.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
                .padding(.vertical, BaseViewLayout.spacing)
                
                if showDivider {
                    Color.secondary.frame(height: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
