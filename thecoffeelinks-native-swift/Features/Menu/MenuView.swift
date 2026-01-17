//
//  MenuView.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

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
                    if menuViewModel.isLoading {
                        ProductGridSkeleton()
                    } else if menuViewModel.filteredProducts.isEmpty {
                        EmptyMenuState()
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: AppLayout.spacing)], spacing: AppLayout.spacing) {
                            ForEach(menuViewModel.filteredProducts) { product in
                                ProductNode(product: product)
                                    .onTapGesture {
                                        selectedProduct = product
                                    }
                            }
                        }
                        .padding(AppLayout.spacing)
                        .padding(.bottom, cartViewModel.isEmpty ? 20 : 120)
                    }
                }
                .refreshable {
                    await menuViewModel.refresh()
                }
            }
            
            // Cart Monitor (Floating)
            if !cartViewModel.isEmpty {
                CartMonitor()
            }
        }
        .fullScreenCover(item: $selectedProduct) { product in
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

struct ProductNode: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            if let imageUrl = product.displayImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.surfaceCard
                    }
                }
                .frame(height: 160)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.surfaceCard)
                    .frame(height: 160)
                    .overlay {
                        Image(systemName: "photo")
                            .font(AppFont.productTitle)
                            .foregroundStyle(Color.textMuted)
                    }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(AppFont.body)
                    .foregroundColor(Color.textInk)
                    .lineLimit(2)
                
                Text(product.priceRange)
                    .font(AppFont.monoBody)
                    .foregroundColor(Color.primaryEspresso)
            }
            .padding(AppLayout.spacingMedium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceCard)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
    }
}

struct CartMonitor: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var showCheckout = false
    
    var body: some View {
        Button {
            showCheckout = true
        } label: {
            HStack {
                Text("\(cartViewModel.itemCount) item\(cartViewModel.itemCount == 1 ? "" : "s") in your cart")
                    .font(AppFont.body)
                    .foregroundColor(Color.textInk)
                
                Spacer()
                
                Text(cartViewModel.total.formattedCurrency)
                    .font(AppFont.monoBody.bold())
                    .foregroundStyle(Color.backgroundPaper)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
            .padding(AppLayout.spacing)
            .background(Color.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(Color.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
            .padding(AppLayout.spacing)
        }
        .fullScreenCover(isPresented: $showCheckout) {
            CheckoutView()
        }
    }
}

// MARK: - Utilities

struct ProductGridSkeleton: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: AppLayout.spacing)], spacing: AppLayout.spacing) {
            ForEach(0..<6, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(Color.surfaceCard)
                        .frame(height: 160)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Rectangle().fill(Color.border).frame(height: 14)
                        Rectangle().fill(Color.border).frame(width: 60, height: 12)
                    }
                    .padding(AppLayout.spacingMedium)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(Color.border, lineWidth: 1)
                )
            }
        }
        .padding(AppLayout.spacing)
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
