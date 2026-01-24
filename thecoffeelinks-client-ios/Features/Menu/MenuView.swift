//
//  MenuView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import CachedAsyncImage // CHANGED

struct MenuView: View {
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var selectedProduct: Product?
    @State private var scrollOffset = CGFloat.zero
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search and Categories Header
                VStack(spacing: AppLayout.spacing) {
                    // Search Field
                    HStack(spacing: AppLayout.spacingMedium) {
                        Image(systemName: "magnifyingglass")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                        
                        TextField("Search our menu...", text: $menuViewModel.searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(AppFont.body)
                            .foregroundStyle(Color.textInk)
                        
                        if !menuViewModel.searchQuery.isEmpty {
                            Button {
                                menuViewModel.searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                    }
                    .padding(.horizontal, AppLayout.spacing)
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppLayout.spacingMedium) {
                            CategoryNode(
                                title: "All",
                                isSelected: menuViewModel.selectedCategory == nil
                            ) {
                                menuViewModel.selectCategory(nil)
                            }
                            
                            ForEach(menuViewModel.categories) { category in
                                CategoryNode(
                                    title: category.displayName,
                                    isSelected: menuViewModel.selectedCategory == category
                                ) {
                                    menuViewModel.selectCategory(category)
                                }
                            }
                        }
                        .padding(.horizontal, AppLayout.spacing)
                    }
                    
                    Color.secondary.frame(height: 1)
                }
                .padding(.top, AppLayout.spacingMedium)
                .background(Color.backgroundPaper)
                
                // Product Grid
                ScrollView {
                    // Stale-While-Revalidate: Only show skeleton if we have NO data and are loading.
                    // If we have data, show it even if refreshing.
                    if menuViewModel.isLoading && menuViewModel.filteredProducts.isEmpty {
                        ProductGridSkeleton()
                    } else if menuViewModel.filteredProducts.isEmpty && !menuViewModel.isLoading {
                        EmptyMenuState()
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: AppLayout.spacing), GridItem(.flexible(), spacing: AppLayout.spacing)], spacing: AppLayout.spacingLarge) {
                            ForEach(menuViewModel.filteredProducts) { product in
                                ProductCard(product: product)
                                    .onTapGesture {
                                        selectedProduct = product
                                    }
                            }
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        .padding(.bottom, cartViewModel.isEmpty ? AppLayout.spacingLarge : AppLayout.spacing * 8)
                        .padding(.top, AppLayout.spacing)
                    }
                }
                .refreshable {
                    await menuViewModel.refresh()
                }
            }
            

        }
        .sheet(item: $selectedProduct) { product in
            ProductDetailSheet(product: product)
        }
        .onAppear {
            Task { await menuViewModel.load() }
        }
    }
}

// MARK: - Components

struct CategoryNode: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.monoBody)
                .foregroundColor(isSelected ? Color.backgroundPaper : Color.textMuted)
                .padding(AppLayout.spacingMicro)
                .background(isSelected ? Color.textInk : Color.backgroundPaper)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(isSelected ? Color.textInk : Color.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        }
    }
}

struct ProductCard: View {
    let product: Product
    
    // REDESIGN: Vertical Grid, minimal, receipt-inspired
    // Constraints: Image on top (square), ONLY Medium price
    // Spacing: Derived from 18pt system (Unit: 18, Half: 9)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image (perfect square using GeometryReader)
            GeometryReader { geo in
                let size = geo.size.width
                // CHANGED: Using CachedAsyncImage
                CachedAsyncImage(url: URL(string: product.displayImageUrl ?? "")) { phase in // CHANGED
                    switch phase { // CHANGED
                    case .empty: // CHANGED
                        Rectangle() // CHANGED
                            .fill(Color.surfaceCard) // CHANGED
                            .overlay { // CHANGED
                                ProgressView() // CHANGED
                                    .tint(Color.primaryEspresso) // CHANGED
                            } // CHANGED
                    case .success(let image): // CHANGED
                        image // CHANGED
                            .resizable() // CHANGED
                            .aspectRatio(contentMode: .fill) // CHANGED
                    case .failure: // CHANGED
                        Rectangle() // CHANGED
                            .fill(Color.surfaceCard) // CHANGED
                            .overlay { // CHANGED
                                Image(systemName: "photo") // CHANGED
                                    .font(AppFont.monoCaption) // CHANGED
                                    .foregroundStyle(Color.textMuted) // CHANGED
                            } // CHANGED
                    @unknown default: // CHANGED
                        EmptyView() // CHANGED
                    } // CHANGED
                } // CHANGED
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                .overlay {
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(Color.border.opacity(0.3), lineWidth: 1)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            
            VStack(alignment: .leading, spacing: AppLayout.spacingSmall) {
                // Name (Primary Anchor - Libre Baskerville Bold)
                // Limited to 1 line for a punchier, single-row alignment
                Text(product.name)
                    .font(AppFont.productTitle)
                    .tracking(0.3)
                    .foregroundColor(Color.textInk)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.85)
                
                // Meta Row (Size · Price)
                let mediumPrice = product.sizeOptions.first(where: { $0.size == .medium })?.price ?? product.basePrice
                
                HStack(spacing: 6) {
                    Text("MEDIUM")
                        .font(AppFont.monoCaption)
                        .tracking(1.0)
                        .foregroundColor(Color.textInk.opacity(0.6))
                    
                    Text("·")
                        .font(AppFont.monoCaption)
                        .foregroundColor(Color.primaryEspresso)
                    
                    // Price: 85% opacity, [price]₫ format
                    Text(mediumPrice.toVND())
                        .font(AppFont.monoBody)
                        .foregroundColor(Color.textInk.opacity(0.85))
                }
                .textCase(.uppercase)
            }
            .padding(.top, AppLayout.spacingMedium) // 12pt grounded gap
            .padding(.bottom, AppLayout.spacingCompact)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(0)
        .background(Color.backgroundPaper)
    }
}



// MARK: - Utilities

struct ProductGridSkeleton: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: AppLayout.spacing), GridItem(.flexible(), spacing: AppLayout.spacing)], spacing: AppLayout.spacingLarge) {
            ForEach(0..<6, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(Color.surfaceCard)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    
                    VStack(alignment: .leading, spacing: AppLayout.spacingSmall) {
                        Rectangle().fill(Color.border).frame(height: 18)
                        Rectangle().fill(Color.border).frame(width: 80, height: 14)
                    }
                    .padding(.top, AppLayout.halfUnit)
                }
            }
        }
        .padding(.horizontal, AppLayout.spacing)
    }
}

struct EmptyMenuState: View {
    var body: some View {
        VStack(spacing: AppLayout.spacingXL) {
            Text("No items found")
                .font(AppFont.sectionHeader)
                .foregroundColor(Color.textInk)
            
            Text("Try searching for something else.")
                .font(AppFont.body)
                .foregroundColor(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(60)
    }
}
