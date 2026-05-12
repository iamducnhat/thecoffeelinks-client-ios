//
//  ProductModels.swift
//  thecoffeelinks-client-ios
//
//  Domain models for products - NO SwiftUI imports
//

import Foundation

enum ProductInventoryState: String, Codable, Hashable, Sendable {
    case available
    case soldOut = "sold_out"
}

// MARK: - Type Aliases for External Access
typealias ProductCategory = Category

// Retrigger check
// MARK: - Product
//
// struct Product: Codable, Identifiable, Hashable, Sendable { ... }
// This file was confirmed Sendable in previous step.
// The error likely comes from OrderModels.swift references.
// I will wait for OrderModels view.

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
    let isStoreAvailable: Bool?
    let inventoryState: ProductInventoryState?
    let quantityOnHand: Int?
    let hasStoreOverride: Bool
    let usesQuantityInventory: Bool
    let isHotSupported: Bool
    let isDeliverable: Bool
    let deliveryPrepMinutes: Int?
    let tags: [String]
    let nutritionInfo: NutritionInfo?
    let allergens: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case categoryId = "category_id"
        case categoryName = "category_name"
        case imageUrl = "image_url"
        case basePrice = "base_price"
        case sizeOptions = "size_options"
        case availableToppings = "available_toppings"
        case isPopular = "is_popular"
        case isNew = "is_new"
        case isActive = "is_active"
        case isStoreAvailable = "is_store_available"
        case inventoryState = "inventory_state"
        case quantityOnHand = "quantity_on_hand"
        case hasStoreOverride = "has_store_override"
        case usesQuantityInventory = "uses_quantity_inventory"
        case isHotSupported = "is_hot_supported"
        case isDeliverable = "is_deliverable"
        case deliveryPrepMinutes = "delivery_prep_minutes"
        case tags
        case nutritionInfo = "nutrition_info"
        case allergens
    }
    
    nonisolated init(id: String, name: String, description: String?, categoryId: String, categoryName: String?, imageUrl: String?, basePrice: Double, sizeOptions: [SizeOption], availableToppings: [String], isPopular: Bool, isNew: Bool, isActive: Bool, isStoreAvailable: Bool? = nil, inventoryState: ProductInventoryState? = nil, quantityOnHand: Int? = nil, hasStoreOverride: Bool = false, usesQuantityInventory: Bool = false, isHotSupported: Bool, isDeliverable: Bool, deliveryPrepMinutes: Int?, tags: [String], nutritionInfo: NutritionInfo?, allergens: [String]) {
        self.id = id
        self.name = name
        self.description = description
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.imageUrl = imageUrl
        self.basePrice = basePrice
        self.sizeOptions = sizeOptions
        self.availableToppings = availableToppings
        self.isPopular = isPopular
        self.isNew = isNew
        self.isActive = isActive
        self.isStoreAvailable = isStoreAvailable
        self.inventoryState = inventoryState
        self.quantityOnHand = quantityOnHand
        self.hasStoreOverride = hasStoreOverride
        self.usesQuantityInventory = usesQuantityInventory
        self.isHotSupported = isHotSupported
        self.isDeliverable = isDeliverable
        self.deliveryPrepMinutes = deliveryPrepMinutes
        self.tags = tags
        self.nutritionInfo = nutritionInfo
        self.allergens = allergens
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        categoryId = try container.decode(String.self, forKey: .categoryId)
        categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        basePrice = try container.decode(Double.self, forKey: .basePrice)
        sizeOptions = try container.decode([SizeOption].self, forKey: .sizeOptions)
        availableToppings = try container.decode([String].self, forKey: .availableToppings)
        isPopular = try container.decode(Bool.self, forKey: .isPopular)
        isNew = try container.decode(Bool.self, forKey: .isNew)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        isStoreAvailable = try container.decodeIfPresent(Bool.self, forKey: .isStoreAvailable)
        inventoryState = try container.decodeIfPresent(ProductInventoryState.self, forKey: .inventoryState)
        quantityOnHand = try container.decodeIfPresent(Int.self, forKey: .quantityOnHand)
        hasStoreOverride = try container.decodeIfPresent(Bool.self, forKey: .hasStoreOverride) ?? false
        usesQuantityInventory = try container.decodeIfPresent(Bool.self, forKey: .usesQuantityInventory) ?? false
        isHotSupported = try container.decodeIfPresent(Bool.self, forKey: .isHotSupported) ?? false
        isDeliverable = try container.decode(Bool.self, forKey: .isDeliverable)
        deliveryPrepMinutes = try container.decodeIfPresent(Int.self, forKey: .deliveryPrepMinutes)
        tags = try container.decode([String].self, forKey: .tags)
        nutritionInfo = try container.decodeIfPresent(NutritionInfo.self, forKey: .nutritionInfo)
        allergens = try container.decode([String].self, forKey: .allergens)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encodeIfPresent(categoryName, forKey: .categoryName)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(basePrice, forKey: .basePrice)
        try container.encode(sizeOptions, forKey: .sizeOptions)
        try container.encode(availableToppings, forKey: .availableToppings)
        try container.encode(isPopular, forKey: .isPopular)
        try container.encode(isNew, forKey: .isNew)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(isStoreAvailable, forKey: .isStoreAvailable)
        try container.encodeIfPresent(inventoryState, forKey: .inventoryState)
        try container.encodeIfPresent(quantityOnHand, forKey: .quantityOnHand)
        try container.encode(hasStoreOverride, forKey: .hasStoreOverride)
        try container.encode(usesQuantityInventory, forKey: .usesQuantityInventory)
        try container.encode(isHotSupported, forKey: .isHotSupported)
        try container.encode(isDeliverable, forKey: .isDeliverable)
        try container.encodeIfPresent(deliveryPrepMinutes, forKey: .deliveryPrepMinutes)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(nutritionInfo, forKey: .nutritionInfo)
        try container.encode(allergens, forKey: .allergens)
    }
    
    var canBeDelivered: Bool { isDeliverable && isActive }
    var price: Double { basePrice } // UI Compatibility
    var isSoldOut: Bool { inventoryState == .soldOut }
    var effectiveAvailability: Bool { isStoreAvailable ?? isActive }
    
    /// Check if product is available at a specific store
    func isAvailableAt(storeId: String?) -> Bool {
        if storeId != nil {
            return effectiveAvailability
        }
        return isActive && isDeliverable
    }
    
    var priceRange: String {
        guard let minPrice = sizeOptions.min(by: { $0.price < $1.price })?.price,
              let maxPrice = sizeOptions.max(by: { $0.price < $1.price })?.price else {
            return basePrice.formattedVND
        }
        if minPrice == maxPrice { return minPrice.formattedVND }
        return "\(minPrice.formattedVND) - \(maxPrice.formattedVND)"
    }
    
    nonisolated func price(for size: ProductSize) -> Double {
        for option in sizeOptions {
            if option.size == size { return option.price }
        }
        #if DEBUG
        debugLog("⚠️ [Product.price] product=\(id) no matching size=\(size). sizeOptions=\(sizeOptions.map { $0.size.rawValue })")
        #endif
        return basePrice
    }
    
    var displayImageUrl: String? {
        guard let rawUrl = imageUrl, !rawUrl.isEmpty else { return nil }
        if rawUrl.hasPrefix("http://") || rawUrl.hasPrefix("https://") { return rawUrl }
        
        // Use Config helper instead of hardcoded URL
        let baseURL = Config.apiBaseURL
        if rawUrl.hasPrefix("/") { return baseURL + rawUrl }
        return baseURL + "/" + rawUrl
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Size Option

struct SizeOption: Codable, Hashable, Sendable {
    let size: ProductSize
    let price: Double
    let isEnabled: Bool
    
    nonisolated init(size: ProductSize, price: Double, isEnabled: Bool) {
        self.size = size
        self.price = price
        self.isEnabled = isEnabled
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
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case displayName = "display_name"
        case iconName = "icon_name"
        case imageUrl = "image_url"
        case sortOrder = "sort_order"
        case isActive = "is_active"
        case productCount = "product_count"
    }

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
    
    enum CodingKeys: String, CodingKey {
        case id, name, price
        case isAvailable = "is_available"
        case maxQuantity = "max_quantity"
        case categoryId = "category_id"
    }
    
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
    
    enum CodingKeys: String, CodingKey {
        case id, product, rank, trend
        case orderCount = "order_count"
    }
    
    init(id: String, product: Product, orderCount: Int, rank: Int, trend: PopularityTrend) {
        self.id = id
        self.product = product
        self.orderCount = orderCount
        self.rank = rank
        self.trend = trend
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        product = try container.decode(Product.self, forKey: .product)
        orderCount = try container.decode(Int.self, forKey: .orderCount)
        rank = try container.decode(Int.self, forKey: .rank)
        trend = try container.decode(PopularityTrend.self, forKey: .trend)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(product, forKey: .product)
        try container.encode(orderCount, forKey: .orderCount)
        try container.encode(rank, forKey: .rank)
        try container.encode(trend, forKey: .trend)
    }
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

struct APIPopularProductsResponse: Codable {
    let products: [APIPopularProductItem]
    let period: String?
    let count: Int?
}

struct APIPopularProductItem: Codable {
    let id: String
    let orderCount: Int?
    let period: String?
}

// MARK: - Currency Formatting

extension NumberFormatter {
    static let vndTight: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "vi_VN")
        f.currencyCode = "VND"
        f.maximumFractionDigits = 0
        return f
    }()
}

extension Double {

    /// Vietnamese Dong, symbol attached tightly to number (e.g. 10.000₫)
    nonisolated var formattedVND: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.currencyCode = "VND"
        formatter.maximumFractionDigits = 0
        
        let raw = formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))₫"
        
        // Remove all spaces (including non-breaking space)
        return raw.replacingOccurrences(
            of: "\\s+",
            with: "",
            options: .regularExpression
        )
    }

    func toVND() -> String {
        formattedVND
    }
}
