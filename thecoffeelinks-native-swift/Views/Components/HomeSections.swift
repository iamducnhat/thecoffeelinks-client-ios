//
//  HomeSections.swift
//  thecoffeelinks-native-swift
//
//  Home page sections for the Ordering Engine pattern.
//  Includes: FavoritesSection, PopularSection, ContextAwareSection
//

import SwiftUI

// MARK: - Favorites Section

struct FavoritesSection: View {
    @ObservedObject private var favoritesService = FavoritesService.shared
    @State private var showFavoritesManager = false
    
    var body: some View {
        if !favoritesService.favorites.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("Favorites")
                        .font(.brandSerif(20))
                        .foregroundStyle(Color.coffeeDark)
                    
                    Spacer()
                    
                    Button {
                        showFavoritesManager = true
                    } label: {
                        Text("Manage")
                            .font(.caption)
                            .foregroundStyle(Color.forestCanopy)
                    }
                }
                .padding(.horizontal)
                
                // Horizontal scroll of favorites
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(favoritesService.favorites.prefix(6)) { favorite in
                            FavoriteItemCard(favorite: favorite)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .sheet(isPresented: $showFavoritesManager) {
                FavoritesManagerView()
            }
        }
    }
}

struct FavoriteItemCard: View {
    let favorite: FavoriteItem
    @ObservedObject private var cartManager = CartManager.shared
    
    @State private var showingCustomization = false
    @State private var showAddedFeedback = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product image
            AsyncImage(url: URL(string: favorite.product.displayImageUrl ?? "")) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.neutral100)
                    .overlay {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color.neutral300)
                    }
            }
            .frame(width: 100, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .padding(6)
                    .background(Color.white)
                    .clipShape(Circle())
                    .padding(4)
            }
            
            // Product info
            VStack(alignment: .leading, spacing: 2) {
                Text(favorite.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(Color.forestCanopy)
                    .lineLimit(1)
                
                Text(favorite.priceForSize.toVND())
                    .font(.caption2)
                    .foregroundStyle(Color.neutral600)
                
                // Notes indicator
                if favorite.activeNotes.count > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "note.text")
                            .font(.system(size: 8))
                        Text("\(favorite.activeNotes.count) note\(favorite.activeNotes.count > 1 ? "s" : "")")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(Color.neutral500)
                }
            }
        }
        .frame(width: 100)
        .onTapGesture {
            addToCart()
        }
        .onLongPressGesture {
            showingCustomization = true
        }
        .overlay(alignment: .center) {
            if showAddedFeedback {
                Text("Added!")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.forestCanopy)
                    .cornerRadius(8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showingCustomization) {
            OrderCustomizationView(product: favorite.product)
        }
    }
    
    private func addToCart() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        cartManager.addToCart(
            product: favorite.product,
            quantity: 1,
            finalPrice: favorite.priceForSize,
            customization: favorite.customization
        )
        
        withAnimation(.spring(response: 0.3)) {
            showAddedFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showAddedFeedback = false
            }
        }
    }
}

// MARK: - Popular Right Now Section

struct PopularRightNowSection: View {
    let products: [Product]
    let orderCounts: [String: Int] // productId -> orders today
    
    // Anti-herd: max 3 popular items shown
    private let maxItems = 3
    // Anti-herd: minimum orders to be "popular"
    private let minOrders = 5
    
    var popularProducts: [Product] {
        products
            .filter { (orderCounts[$0.id] ?? 0) >= minOrders }
            .sorted { (orderCounts[$0.id] ?? 0) > (orderCounts[$1.id] ?? 0) }
            .prefix(maxItems)
            .map { $0 }
    }
    
    var body: some View {
        if !popularProducts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("Popular right now")
                        .font(.brandSerif(20))
                        .foregroundStyle(Color.coffeeDark)
                    
                    Spacer()
                    
                    // Subtle count, not aggressive
                    Text("at this store")
                        .font(.caption)
                        .foregroundStyle(Color.neutral500)
                }
                .padding(.horizontal)
                
                // Products
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(popularProducts) { product in
                            PopularProductCard(
                                product: product,
                                orderCount: orderCounts[product.id] ?? 0
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct PopularProductCard: View {
    let product: Product
    let orderCount: Int
    
    @State private var showingCustomization = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image with popularity badge
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: product.displayImageUrl ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.neutral100)
                }
                .frame(width: 140, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Order count badge (subtle)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(orderCount) today")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
                .padding(8)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.forestCanopy)
                    .lineLimit(1)
                
                if let price = product.sizeOptions?.medium.price {
                    Text(price.toVND())
                        .font(.caption)
                        .foregroundStyle(Color.neutral600)
                }
            }
        }
        .frame(width: 140)
        .onTapGesture {
            showingCustomization = true
        }
        .sheet(isPresented: $showingCustomization) {
            OrderCustomizationView(product: product)
        }
    }
}

// MARK: - Context Aware Section (Time/Weather based)

struct ContextAwareSection: View {
    let products: [Product]
    @EnvironmentObject var appState: AppState
    
    var contextTitle: String {
        switch appState.timeMode {
        case .morning: return "Morning fuel"
        case .day: return "Afternoon pick-me-up"
        case .evening: return "Evening treat"
        }
    }
    
    var contextProducts: [Product] {
        // Filter products based on time context
        let category: String
        switch appState.timeMode {
        case .morning: category = "coffee"
        case .day: category = "coffee"
        case .evening: category = "tea"
        }
        
        return products
            .filter { $0.category?.lowercased().contains(category) == true }
            .prefix(4)
            .map { $0 }
    }
    
    var body: some View {
        if !contextProducts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(contextTitle)
                    .font(.brandSerif(20))
                    .foregroundStyle(Color.coffeeDark)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(contextProducts) { product in
                            ProductCard(product: product, width: 160)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Regulars Here Now (Passive Social)

struct RegularsHereNowSection: View {
    let regularsCount: Int
    let connectedNames: [String] // People user has connected with before
    
    var body: some View {
        if regularsCount > 0 || !connectedNames.isEmpty {
            HStack(spacing: 12) {
                // Avatar stack
                ZStack {
                    ForEach(0..<min(3, regularsCount + connectedNames.count), id: \.self) { index in
                        Circle()
                            .fill(Color.neutral200)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.neutral400)
                            }
                            .offset(x: CGFloat(index * 16))
                    }
                }
                .frame(width: CGFloat(min(3, regularsCount + connectedNames.count) * 16 + 12), alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    if !connectedNames.isEmpty {
                        Text("\(connectedNames.first ?? "") is here")
                            .font(.caption.bold())
                            .foregroundStyle(Color.forestCanopy)
                    }
                    
                    if regularsCount > 0 {
                        Text("\(regularsCount) regulars here now")
                            .font(.caption)
                            .foregroundStyle(Color.neutral600)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color.filteredLight.opacity(0.3))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - Previews

#Preview("Favorites Section") {
    ZStack {
        Color.morningFog.ignoresSafeArea()
        
        VStack {
            FavoritesSection()
            Spacer()
        }
    }
}

#Preview("Regulars Here Now") {
    RegularsHereNowSection(
        regularsCount: 5,
        connectedNames: ["Minh", "Lan"]
    )
}
