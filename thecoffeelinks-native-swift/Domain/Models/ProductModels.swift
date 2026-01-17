//
//  ProductModels.swift
//  thecoffeelinks-native-swift
//
//  Domain models for products - NO SwiftUI imports
//

import Foundation

// MARK: - Product

struct Product: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String?
    let categoryId: String
    let categoryName: String?
    let imageUrl: String?
    let basePrice: Double
    let sizeOptions: [SizeOption]
    let availableToppings: [String]
    let isPopular: Bool
    let isNew: Bool
    let isActive: Bool
    let isDeliverable: Bool
    let deliveryPrepMinutes: Int?
    let tags: [String]
    let nutritionInfo: NutritionInfo?
    let allergens: [String]
    
    var canBeDelivered: Bool { isDeliverable && isActive }
    var price: Double { basePrice } // UI Compatibility
    
    var priceRange: String {
        guard let minPrice = sizeOptions.min(by: { $0.price < $1.price })?.price,
              let maxPrice = sizeOptions.max(by: { $0.price < $1.price })?.price else {
            return basePrice.formattedCurrency
        }
        if minPrice == maxPrice { return minPrice.formattedCurrency }
        return "\(minPrice.formattedCurrency) - \(maxPrice.formattedCurrency)"
    }
    
    func price(for size: ProductSize) -> Double {
        sizeOptions.first { $0.size == size }?.price ?? basePrice
    }
    
    var displayImageUrl: String? {
        guard let rawUrl = imageUrl, !rawUrl.isEmpty else { return nil }
        if rawUrl.hasPrefix("http://") || rawUrl.hasPrefix("https://") { return rawUrl }
        if rawUrl.hasPrefix("/") { return "https://server-nu-three-90.vercel.app" + rawUrl }
        return "https://server-nu-three-90.vercel.app/" + rawUrl
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Size Option

struct SizeOption: Codable, Hashable, Sendable {
    let size: ProductSize
    let price: Double
    let isEnabled: Bool
}

// MARK: - API Size Options (matches API format exactly)

struct APISizeOption: Codable {
    let enabled: Bool
    let price: Double
}

struct APIProductSizeOptions: Codable {
    let small: APISizeOption
    let medium: APISizeOption
    let large: APISizeOption
    
    func toSizeOptions() -> [SizeOption] {
        var options: [SizeOption] = []
        if small.enabled { options.append(SizeOption(size: .small, price: small.price, isEnabled: true)) }
        if medium.enabled { options.append(SizeOption(size: .medium, price: medium.price, isEnabled: true)) }
        if large.enabled { options.append(SizeOption(size: .large, price: large.price, isEnabled: true)) }
        return options
    }
}

// MARK: - Category

struct Category: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let displayName: String
    let iconName: String?
    let imageUrl: String?
    let sortOrder: Int
    let isActive: Bool
    let productCount: Int?
    
    static func == (lhs: Category, rhs: Category) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Topping

struct Topping: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let price: Double
    let isAvailable: Bool
    let maxQuantity: Int
    let categoryId: String?
    
    static func == (lhs: Topping, rhs: Topping) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Nutrition Info

struct NutritionInfo: Codable, Hashable, Sendable {
    let calories: Int?
    let caffeine: Int?
    let sugar: Int?
    let protein: Int?
}

// MARK: - Menu

struct Menu: Codable, Sendable {
    let categories: [Category]
    let products: [Product]
    let toppings: [Topping]
    let lastUpdated: Date
    
    func products(for categoryId: String) -> [Product] {
        products.filter { $0.categoryId == categoryId && $0.isActive }
    }
    
    func deliverableProducts() -> [Product] {
        products.filter { $0.canBeDelivered }
    }
    
    func popularProducts(limit: Int = 10) -> [Product] {
        Array(products.filter { $0.isPopular && $0.isActive }.prefix(limit))
    }
    
    func newProducts(limit: Int = 10) -> [Product] {
        Array(products.filter { $0.isNew && $0.isActive }.prefix(limit))
    }
}

// MARK: - Popular Products (Server-Driven)

struct PopularProductsResponse: Codable, Sendable {
    let products: [PopularProduct]
    let period: String?
}

struct PopularProduct: Codable, Identifiable, Sendable {
    let id: String
    let product: Product
    let orderCount: Int
    let rank: Int
    let trend: PopularityTrend
}

enum PopularityTrend: String, Codable, Sendable {
    case rising
    case stable
    case falling
}

// MARK: - API Responses

struct ProductsResponse: Codable, Sendable {
    let products: [Product]
}

struct CategoriesResponse: Codable, Sendable {
    let categories: [Category]
}

struct ToppingsResponse: Codable, Sendable {
    let toppings: [Topping]
}

struct MenuResponse: Codable, Sendable {
    let menu: Menu
}

// MARK: - API Response DTOs (simplified to match API directly)

struct APIMenuResponse: Codable {
    let categories: [MenuCategory]
    let products: [APIProduct]
    let toppings: [APITopping]
    let sizes: [String: SizeInfo]?
    let sugarOptions: [ConfigOption]?
    let iceOptions: [ConfigOption]?
    
    struct MenuCategory: Codable {
        let id: String
        let name: String
    }
    
    struct APIProduct: Codable {
        let id: String
        let name: String
        let description: String?
        let category: String?
        let categoryId: String
        let image: String?
        let isPopular: Bool
        let isNew: Bool
        let isAvailable: Bool
        let availableToppings: [String]
        let sizeOptions: APIProductSizeOptions
    }
    
    struct APITopping: Codable {
        let id: String
        let name: String
        let price: Double
        let isAvailable: Bool
        let createdAt: String?
    }
    
    struct SizeInfo: Codable {
        let price: Double
        let label: String
    }
    
    struct ConfigOption: Codable {
        let value: String
        let label: String
    }
    
    // Convert to domain Menu
    func toMenu() -> Menu {
        let categories = self.categories.map { Category(
            id: $0.id,
            name: $0.name,
            displayName: $0.name,
            iconName: nil,
            imageUrl: nil,
            sortOrder: 0,
            isActive: true,
            productCount: nil
        )}
        
        let products = self.products.map { apiProd in
            let sizeOpts = apiProd.sizeOptions.toSizeOptions()
            return Product(
                id: apiProd.id,
                name: apiProd.name,
                description: apiProd.description,
                categoryId: apiProd.categoryId,
                categoryName: apiProd.category,
                imageUrl: apiProd.image,
                basePrice: sizeOpts.first?.price ?? 0,
                sizeOptions: sizeOpts,
                availableToppings: apiProd.availableToppings,
                isPopular: apiProd.isPopular,
                isNew: apiProd.isNew,
                isActive: apiProd.isAvailable,
                isDeliverable: true,
                deliveryPrepMinutes: nil,
                tags: [],
                nutritionInfo: nil,
                allergens: []
            )
        }
        
        let toppings = self.toppings.map { Topping(
            id: $0.id,
            name: $0.name,
            price: $0.price,
            isAvailable: $0.isAvailable,
            maxQuantity: 5,
            categoryId: nil
        )}
        
        return Menu(
            categories: categories,
            products: products,
            toppings: toppings,
            lastUpdated: Date()
        )
    }
}

// MARK: - Currency Formatting

extension Double {
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.currencySymbol = "₫"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))₫"
    }
    
    func toVND() -> String { formattedCurrency }
}
