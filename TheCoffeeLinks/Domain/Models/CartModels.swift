//
//  CartModels.swift
//  thecoffeelinks-client-ios
//
//  Domain models for shopping cart - NO SwiftUI imports
//

import Foundation

// MARK: - Cart Item

// MARK: - Cart Item

struct CartItem: Codable, Identifiable, Hashable, Sendable {
    /// Deterministic identity key
    let key: String
    
    /// Conformance to Identifiable
    var id: String { key }
    
    let product: Product
    var quantity: Int
    var customization: OrderCustomization
    let addedAt: Date
    
    /// The price per unit at the time of addition (used for strict equality)
    let priceSnapshot: Double
    
    /// Store ID determines cart context (used for key generation)
    let storeId: String
    
    var unitPrice: Double {
        // We use the snapshot price as the source of truth for calculations
        // to ensure the total doesn't fluctuate if backend price changes
        priceSnapshot
    }
    
    var totalPrice: Double { unitPrice * Double(quantity) }
    var displayCustomization: String { customization.displayText }
    
    enum CodingKeys: String, CodingKey {
        case key, product, quantity, customization
        case addedAt = "added_at"
        case priceSnapshot = "price_snapshot"
        case storeId = "store_id"
    }

    nonisolated init(key: String, product: Product, quantity: Int, customization: OrderCustomization, addedAt: Date, priceSnapshot: Double, storeId: String) {
        self.key = key
        self.product = product
        self.quantity = quantity
        self.customization = customization
        self.addedAt = addedAt
        self.priceSnapshot = priceSnapshot
        self.storeId = storeId
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        product = try container.decode(Product.self, forKey: .product)
        quantity = try container.decode(Int.self, forKey: .quantity)
        customization = try container.decode(OrderCustomization.self, forKey: .customization)
        addedAt = try container.decode(Date.self, forKey: .addedAt)
        
        // Backward compatibility: Handle missing price_snapshot
        if let snapshot = try container.decodeIfPresent(Double.self, forKey: .priceSnapshot) {
            priceSnapshot = snapshot
        } else {
            // Recalculate from current product state if missing
            priceSnapshot = product.basePrice + customization.toppingsTotal
        }
        
        // Backward compatibility: Handle missing store_id
        if let sId = try container.decodeIfPresent(String.self, forKey: .storeId) {
            storeId = sId
        } else {
            // Default or empty for legacy items. 
            // Warning: Key generation might diverge if storeId changes. 
            // Ideally we'd inject this, but for now empty string allows recovery.
            storeId = "" 
        }
        
        // Backward compatibility: If key is missing, generate it
        if let decodedKey = try container.decodeIfPresent(String.self, forKey: .key) {
            key = decodedKey
        } else {
            key = CartItem.generateKey(
                product: product,
                modifiers: customization,
                priceSnapshot: priceSnapshot,
                storeId: storeId
            )
        }
    }

    static func == (lhs: CartItem, rhs: CartItem) -> Bool { lhs.key == rhs.key }
    func hash(into hasher: inout Hasher) { hasher.combine(key) }
    
    /// Generates a deterministic key for the item
    nonisolated static func generateKey(product: Product, modifiers: OrderCustomization, priceSnapshot: Double, storeId: String) -> String {
        // Normalizing modifiers
        // 1. Toppings sorted by ID to ensure order independence
        let sortedToppings = modifiers.toppings.sorted { $0.id < $1.id }
        let toppingsStr = sortedToppings.map { "\($0.id):\($0.quantity)" }.joined(separator: ",")
        
        // 2. Build parts list
        let components: [String] = [
            storeId,
            product.id,
            modifiers.size.rawValue,
            modifiers.sugar?.rawValue ?? "nil",
            modifiers.ice?.rawValue ?? "nil",
            toppingsStr,
            String(format: "%.2f", priceSnapshot) // 2 decimal places strictness
        ]
        
        // 3. Create hash string
        return components.joined(separator: "|")
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
    var deliveryNotes: String? // C2 FIX: Separate from staffNotes
    var lastUpdated: Date?
    var isDirty: Bool? // Track if local changes are unsynced
    
    enum CodingKeys: String, CodingKey {
        case items, mode
        case storeId = "store_id"
        case deliveryAddressId = "delivery_address_id"
        case tableId = "table_id"
        case voucherCode = "voucher_code"
        case staffNotes = "staff_notes"
        case deliveryNotes = "delivery_notes"
        case isDirty = "is_dirty"
    }
    
    nonisolated init(items: [CartItem], mode: OrderingMode, storeId: String? = nil, deliveryAddressId: String? = nil, tableId: String? = nil, voucherCode: String? = nil, staffNotes: String? = nil, deliveryNotes: String? = nil, lastUpdated: Date? = nil, isDirty: Bool? = nil) {
        self.items = items
        self.mode = mode
        self.storeId = storeId
        self.deliveryAddressId = deliveryAddressId
        self.tableId = tableId
        self.voucherCode = voucherCode
        self.staffNotes = staffNotes
        self.deliveryNotes = deliveryNotes
        self.lastUpdated = lastUpdated
        self.isDirty = isDirty
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([CartItem].self, forKey: .items)
        mode = try container.decode(OrderingMode.self, forKey: .mode)
        storeId = try container.decodeIfPresent(String.self, forKey: .storeId)
        deliveryAddressId = try container.decodeIfPresent(String.self, forKey: .deliveryAddressId)
        tableId = try container.decodeIfPresent(String.self, forKey: .tableId)
        voucherCode = try container.decodeIfPresent(String.self, forKey: .voucherCode)
        staffNotes = try container.decodeIfPresent(String.self, forKey: .staffNotes)
        deliveryNotes = try container.decodeIfPresent(String.self, forKey: .deliveryNotes)
        lastUpdated = nil // Not persisted
        isDirty = try container.decodeIfPresent(Bool.self, forKey: .isDirty)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(mode, forKey: .mode)
        try container.encodeIfPresent(storeId, forKey: .storeId)
        try container.encodeIfPresent(deliveryAddressId, forKey: .deliveryAddressId)
        try container.encodeIfPresent(tableId, forKey: .tableId)
        try container.encodeIfPresent(voucherCode, forKey: .voucherCode)
        try container.encodeIfPresent(staffNotes, forKey: .staffNotes)
        try container.encodeIfPresent(deliveryNotes, forKey: .deliveryNotes)
        try container.encodeIfPresent(isDirty, forKey: .isDirty)
    }
    
    var isEmpty: Bool { items.isEmpty }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
    var uniqueItemCount: Int { items.count }
    var subtotal: Double { items.reduce(0) { $0 + $1.totalPrice } }
    
    nonisolated mutating func addItem(_ item: CartItem) {
        // Check local state for existing key
        if let existingIndex = items.firstIndex(where: { $0.key == item.key }) {
            // Increment quantity
            items[existingIndex].quantity += item.quantity
            // Update updated_at implied by persistence
        } else {
            // Insert new cart item
            items.append(item)
        }
    }
    
    nonisolated mutating func updateQuantity(for itemKey: String, delta: Int) {
        guard let index = items.firstIndex(where: { $0.key == itemKey }) else { return }
        let newQuantity = items[index].quantity + delta
        if newQuantity <= 0 { 
            items.remove(at: index) 
        } else { 
            items[index].quantity = newQuantity 
        }
    }
    
    nonisolated mutating func removeItem(_ itemKey: String) {
        items.removeAll { $0.key == itemKey }
    }
    
    nonisolated mutating func clear() {
        items.removeAll()
        voucherCode = nil
        staffNotes = nil
        deliveryNotes = nil
    }
    
    nonisolated static var empty: Cart {
        Cart(items: [], mode: .pickup, storeId: nil, deliveryAddressId: nil,
             tableId: nil, voucherCode: nil, staffNotes: nil, deliveryNotes: nil)
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
        var items: [(String, Double, Bool)] = [(String(localized: "cart_summary_subtotal"), subtotal, false)]
        if deliveryFee > 0 { items.append((String(localized: "cart_summary_delivery"), deliveryFee, false)) }
        if discount > 0 { items.append((String(localized: "cart_summary_discount"), -discount, true)) }
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
    let maxUsesPerUser: Int
    let userUsesCount: Int
    let applicableProducts: [String]?
    let applicableModes: [OrderingMode]?
    
    enum DiscountType: String, Codable, Sendable {
        case percentage, fixed, discount
        case freeDelivery = "free_delivery"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, code, description
        case imageUrl = "image_url"
        case discountType = "discount_type"
        case discountValue = "discount_amount"
        case minOrderAmount = "min_order"
        case maxDiscount = "max_discount"
        case validUntil = "valid_until"
        case expiresAt = "expires_at"
        case isActive = "is_active"
        case isUsed = "is_used"
        case maxUsesPerUser = "max_uses_per_user"
        case userUsesCount = "user_uses_count"
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
        maxDiscount = try container.decodeIfPresent(Double.self, forKey: .maxDiscount)
        validUntil = try container.decodeIfPresent(Date.self, forKey: .validUntil)
            ?? container.decodeIfPresent(Date.self, forKey: .expiresAt)
        maxUsesPerUser = try container.decodeIfPresent(Int.self, forKey: .maxUsesPerUser) ?? 1
        userUsesCount = try container.decodeIfPresent(Int.self, forKey: .userUsesCount) ?? 0
        
        // Fields not in API - use defaults
        validFrom = Date.distantPast
        usageLimit = nil
        usedCount = 0
        
        let isUsed = try container.decodeIfPresent(Bool.self, forKey: .isUsed) ?? false
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? !isUsed
        
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
        try container.encodeIfPresent(maxDiscount, forKey: .maxDiscount)
        try container.encodeIfPresent(validUntil, forKey: .validUntil)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(maxUsesPerUser, forKey: .maxUsesPerUser)
        try container.encode(userUsesCount, forKey: .userUsesCount)
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
        case .percentage: return String(localized: "voucher_discount_percentage \(Int(discountValue))")
        case .fixed, .discount: return String(localized: "voucher_discount_off \(discountValue.formattedVND)")
        case .freeDelivery: return String(localized: "voucher_free_delivery")
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


