//
//  CartModels.swift
//  thecoffeelinks-native-swift
//
//  Domain models for shopping cart - NO SwiftUI imports
//

import Foundation

// MARK: - Cart Item

struct CartItem: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let product: Product
    var quantity: Int
    var customization: OrderCustomization
    let addedAt: Date
    
    var unitPrice: Double {
        product.price(for: customization.size) + customization.toppingsTotal
    }
    
    var totalPrice: Double { unitPrice * Double(quantity) }
    var displayCustomization: String { customization.displayText }
    
    static func == (lhs: CartItem, rhs: CartItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    func canMerge(with other: CartItem) -> Bool {
        product.id == other.product.id && customization == other.customization
    }
}

// MARK: - Cart

struct Cart: Codable, Sendable {
    var items: [CartItem]
    var mode: OrderingMode
    var storeId: String?
    var deliveryAddressId: String?
    var tableId: String?
    var voucherCode: String?
    var staffNotes: String?
    
    var isEmpty: Bool { items.isEmpty }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
    var uniqueItemCount: Int { items.count }
    var subtotal: Double { items.reduce(0) { $0 + $1.totalPrice } }
    
    mutating func addItem(_ item: CartItem) {
        if let existingIndex = items.firstIndex(where: { $0.canMerge(with: item) }) {
            items[existingIndex].quantity += item.quantity
        } else {
            items.append(item)
        }
    }
    
    mutating func updateQuantity(for itemId: UUID, delta: Int) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        let newQuantity = items[index].quantity + delta
        if newQuantity <= 0 { items.remove(at: index) }
        else { items[index].quantity = newQuantity }
    }
    
    mutating func removeItem(_ itemId: UUID) {
        items.removeAll { $0.id == itemId }
    }
    
    mutating func clear() {
        items.removeAll()
        voucherCode = nil
        staffNotes = nil
    }
    
    static var empty: Cart {
        Cart(items: [], mode: .pickup, storeId: nil, deliveryAddressId: nil,
             tableId: nil, voucherCode: nil, staffNotes: nil)
    }
}

// MARK: - Cart Summary

struct CartSummary: Sendable {
    let subtotal: Double
    let deliveryFee: Double
    let discount: Double
    let total: Double
    let itemCount: Int
    let meetsMinimum: Bool
    let minimumOrderAmount: Double?
    let remainingForMinimum: Double
    
    var breakdown: [(String, Double, Bool)] {
        var items: [(String, Double, Bool)] = [("Subtotal", subtotal, false)]
        if deliveryFee > 0 { items.append(("Delivery", deliveryFee, false)) }
        if discount > 0 { items.append(("Discount", -discount, true)) }
        return items
    }
}

// MARK: - Voucher

struct Voucher: Codable, Identifiable, Sendable {
    let id: String
    let code: String
    let description: String?
    let imageUrl: String? // Voucher banner image
    let discountType: DiscountType
    let discountValue: Double
    let minOrderAmount: Double?
    let maxDiscount: Double?
    let validFrom: Date
    let validUntil: Date?
    let usageLimit: Int?
    let usedCount: Int
    let isActive: Bool
    let applicableProducts: [String]?
    let applicableModes: [OrderingMode]?
    
    enum DiscountType: String, Codable, Sendable {
        case percentage, fixed, discount
        case freeDelivery = "free_delivery"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, code, description, imageUrl
        case discountType = "type"
        case discountValue = "value"
        case minOrderAmount = "minSpend"
        case maxDiscount = "maxDiscount" // Added mapping
        case validUntil = "expiresAt"
        case isActive = "isUsed" // Note: API has isUsed, we'll invert this
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        code = try container.decode(String.self, forKey: .code)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        discountType = try container.decode(DiscountType.self, forKey: .discountType)
        discountValue = try container.decode(Double.self, forKey: .discountValue)
        minOrderAmount = try container.decodeIfPresent(Double.self, forKey: .minOrderAmount)
        maxDiscount = try container.decodeIfPresent(Double.self, forKey: .maxDiscount) // Decode maxDiscount
        validUntil = try container.decodeIfPresent(Date.self, forKey: .validUntil)
        
        // Fields not in API - use defaults
        validFrom = Date.distantPast
        usageLimit = nil
        usedCount = 0
        
        // isActive is derived from isUsed (inverted) and expiresAt
        let isUsed = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
        isActive = !isUsed
        
        applicableProducts = nil
        applicableModes = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(code, forKey: .code)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(discountType, forKey: .discountType)
        try container.encode(discountValue, forKey: .discountValue)
        try container.encodeIfPresent(minOrderAmount, forKey: .minOrderAmount)
        try container.encodeIfPresent(validUntil, forKey: .validUntil)
        try container.encode(!isActive, forKey: .isActive) // Encode as isUsed
    }
    
    var isValid: Bool {
        guard isActive else { return false }
        let now = Date()
        if let expiry = validUntil {
            return now <= expiry
        }
        return true // If no expiry, it's valid
    }
    
    func calculateDiscount(for subtotal: Double) -> Double {
        guard isValid else { return 0 }
        if let min = minOrderAmount, subtotal < min { return 0 }
        
        var discount: Double
        switch discountType {
        case .percentage: discount = subtotal * (discountValue / 100)
        case .fixed, .discount: discount = discountValue
        case .freeDelivery: return 0
        }
        
        if let max = maxDiscount { discount = min(discount, max) }
        return discount
    }
    
    var displayValue: String {
        switch discountType {
        case .percentage: return "\(Int(discountValue))% OFF"
        case .fixed, .discount: return discountValue.formattedVND + " OFF"
        case .freeDelivery: return "Free Delivery"
        }
    }
    
    // Computed property for display title (since API doesn't provide one)
    var displayTitle: String {
        description ?? code
    }
}

// MARK: - Voucher Validation

struct VoucherValidation: Codable, Sendable {
    let valid: Bool
    let voucher: Voucher?
    let discountAmount: Double
    let message: String?
}

struct VouchersResponse: Codable, Sendable {
    let vouchers: [Voucher]
}

struct VoucherValidationResponse: Codable, Sendable {
    let success: Bool
    let validation: VoucherValidation
}


