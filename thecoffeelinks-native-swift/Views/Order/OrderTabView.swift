//
//  OrderTabView.swift
//  thecoffeelinks-native-swift
//
//  Menu Browser - Main Order Tab per Blueprint
//

import SwiftUI
import Combine

struct OrderTabView: View {
    @StateObject private var viewModel = OrderTabViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    @State private var selectedCategory: String? = nil
    @State private var selectedProduct: Product? = nil
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.products.isEmpty {
                // Skeleton Loading State
                MenuSkeletonView()
            } else if viewModel.products.isEmpty {
                // Empty State
                EmptyStateView(type: .orders) {
                    Task { await viewModel.loadMenu() }
                }
            } else {
                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Store Selector
                        storeSelector
                        
                        // Category Tabs (Sticky)
                        categoryTabs
                        
                        // Your Usuals Section (AI Curated)
                        if !viewModel.usuals.isEmpty {
                            yourUsualsSection
                        }
                        
                        // Products by Category
                        productsSection
                    }
                }
            }
        }
        .background(Color.morningFog)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Order")
                    .font(.headline)
                    .foregroundStyle(Color.forestCanopy)
            }
        }
        .sheet(item: $selectedProduct) { product in
            OrderCustomizationView(product: product)
        }
        .task {
            await viewModel.loadMenu()
        }
    }
    
    // MARK: - Store Selector
    
    private var storeSelector: some View {
        Button {
            // Show store picker
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.sunRay)
                
                Text(viewModel.selectedStoreName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.forestCanopy)
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(Color.neutral500)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
        }
    }
    
    // MARK: - Category Tabs
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.categories, id: \.self) { category in
                    categoryChip(category, isSelected: selectedCategory == category || (selectedCategory == nil && category == viewModel.categories.first))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }
    
    private func categoryChip(_ category: String, isSelected: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedCategory = category
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(category)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.forestCanopy)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.forestCanopy : Color.filteredLight.opacity(0.3))
                .cornerRadius(20)
        }
    }
    
    // MARK: - Your Usuals
    
    private var yourUsualsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.sunRay)
                Text("Your Usuals")
                    .font(.headline)
                    .foregroundStyle(Color.forestCanopy)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.usuals) { item in
                        UsualCard(item: item) {
                            // Quick add to cart
                            cartManager.addToCart(
                                product: item.product,
                                quantity: 1,
                                finalPrice: item.priceForSize,
                                customization: item.customization
                            )
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Products Section
    
    private var productsSection: some View {
        LazyVStack(spacing: 0, pinnedViews: []) {
            ForEach(filteredCategories, id: \.self) { category in
                VStack(alignment: .leading, spacing: 12) {
                    // Category Header
                    Text(category.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(Color.neutral500)
                        .tracking(1)
                        .padding(.horizontal)
                        .padding(.top, 24)
                    
                    // Products in category
                    VStack(spacing: 0) {
                        ForEach(viewModel.products(for: category)) { product in
                            MenuProductRow(product: product) {
                                selectedProduct = product
                            }
                            
                            if product.id != viewModel.products(for: category).last?.id {
                                Divider().padding(.leading, 88)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            
            // Bottom spacing for cart
            Color.clear.frame(height: 120)
        }
    }
    
    private var filteredCategories: [String] {
        if let selected = selectedCategory {
            return [selected]
        }
        return viewModel.categories
    }
}

// MARK: - Usual Card

struct UsualCard: View {
    let item: QuickOrderItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Product Image
                AsyncImage(url: URL(string: item.product.displayImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.neutral100)
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
                
                // Name
                Text(item.product.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.forestCanopy)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Size + Price
                Text("\(item.customization.size) • \(item.priceForSize.toVND())")
                    .font(.caption2)
                    .foregroundStyle(Color.neutral500)
            }
            .frame(width: 100)
            .padding(12)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.forestCanopy.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Menu Product Row

struct MenuProductRow: View {
    let product: Product
    let onTap: () -> Void
    @ObservedObject private var cartManager = CartManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Product Image
                AsyncImage(url: URL(string: product.displayImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.neutral100)
                }
                .frame(width: 72, height: 72)
                .cornerRadius(12)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.forestCanopy)
                        .lineLimit(1)
                    
                    if let desc = product.description {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(Color.neutral500)
                            .lineLimit(2)
                    }
                    
                    // Price
                    if let sizes = product.availableSizes.first {
                        Text(sizes.price.toVND())
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.sunRay)
                    }
                }
                
                Spacer()
                
                // Quick Add Button
                Button {
                    quickAddToCart()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.forestCanopy)
                        .frame(width: 32, height: 32)
                        .background(Color.filteredLight.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func quickAddToCart() {
        // Add with defaults (M, Normal)
        let defaultSize = "M"
        let price = product.sizeOptions?.medium.price ?? 0
        
        cartManager.addToCart(
            product: product,
            quantity: 1,
            finalPrice: price,
            customization: OrderCustomization(
                size: defaultSize,
                ice: "Normal",
                sugar: "Normal",
                toppings: nil
            )
        )
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - ViewModel

@MainActor
class OrderTabViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var categories: [String] = []
    @Published var usuals: [QuickOrderItem] = []
    @Published var selectedStoreName: String = "Loading..."
    @Published var isLoading = false
    
    private let menuRepository = MenuRepository.shared
    
    func loadMenu() async {
        isLoading = true
        
        // Fetch menu first
        await menuRepository.fetchMenu()
        
        if let menuResponse = menuRepository.menu {
            self.products = menuResponse.products
            
            // Extract unique categories
            var uniqueCategories: [String] = []
            for product in self.products {
                if let category = product.category, !uniqueCategories.contains(category) {
                    uniqueCategories.append(category)
                }
            }
            self.categories = uniqueCategories.isEmpty ? ["All"] : uniqueCategories
        }
        
        // Load usuals from QuickOrderService
        self.usuals = QuickOrderService.shared.yourUsuals
        
        // Get nearest store name
        self.selectedStoreName = "Nearest Store" // TODO: Get from GPS
        
        isLoading = false
    }
    
    func products(for category: String) -> [Product] {
        if category == "All" {
            return products
        }
        return products.filter { $0.category == category }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OrderTabView()
    }
}
