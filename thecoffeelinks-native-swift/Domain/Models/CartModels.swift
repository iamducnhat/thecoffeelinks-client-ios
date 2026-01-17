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
    let title: String
    let description: String?
    let discountType: DiscountType
    let discountValue: Double
    let minOrderAmount: Double?
    let maxDiscount: Double?
    let validFrom: Date
    let validUntil: Date
    let usageLimit: Int?
    let usedCount: Int
    let isActive: Bool
    let applicableProducts: [String]?
    let applicableModes: [OrderingMode]?
    
    enum DiscountType: String, Codable, Sendable {
        case percentage, fixed
        case freeDelivery = "free_delivery"
    }
    
    var isValid: Bool {
        let now = Date()
        return isActive && now >= validFrom && now <= validUntil
    }
    
    func calculateDiscount(for subtotal: Double) -> Double {
        guard isValid else { return 0 }
        if let min = minOrderAmount, subtotal < min { return 0 }
        
        var discount: Double
        switch discountType {
        case .percentage: discount = subtotal * (discountValue / 100)
        case .fixed: discount = discountValue
        case .freeDelivery: return 0
        }
        
        if let max = maxDiscount { discount = min(discount, max) }
        return discount
    }
    
    var displayValue: String {
        switch discountType {
        case .percentage: return "\(Int(discountValue))% OFF"
        case .fixed: return discountValue.formattedCurrency + " OFF"
        case .freeDelivery: return "Free Delivery"
        }
    }
}

// MARK: - Voucher Validation

struct VoucherValidation: Codable, Sendable {
    let valid: Bool
    let voucher: Voucher?
    let discountAmount: Double
    let message: String?
}

struct VoucherValidationResponse: Codable, Sendable {
    let success: Bool
    let validation: VoucherValidation
}

struct VouchersListResponse: Codable, Sendable {
    let success: Bool
    let vouchers: [Voucher]
}
