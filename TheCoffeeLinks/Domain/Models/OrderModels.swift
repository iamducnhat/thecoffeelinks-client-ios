//
//  OrderModels.swift
//  thecoffeelinks-client-ios
//
//  Domain models for orders - NO SwiftUI imports
//

import Foundation

// MARK: - Order Status Lifecycle

enum OrderStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case placed
    case received
    case preparing
    case ready
    case delivering
    case completed
    case cancelled
    
    var displayName: String {
        switch self {
        case .pending: return String(localized: "order_status_pending")
        case .placed: return String(localized: "order_status_placed")
        case .received: return String(localized: "order_status_received")
        case .preparing: return String(localized: "order_status_preparing")
        case .ready: return String(localized: "order_status_ready")
        case .delivering: return String(localized: "order_status_delivering")
        case .completed: return String(localized: "order_status_completed")
        case .cancelled: return String(localized: "order_status_cancelled")
        }
    }
    
    var isActive: Bool {
        switch self {
        case .pending, .placed, .received, .preparing, .ready, .delivering:
            return true
        case .completed, .cancelled:
            return false
        }
    }
}

// MARK: - Ordering Mode

enum OrderingMode: String, Codable, CaseIterable, Sendable {
    case pickup
    case dineIn = "dine_in"
    case delivery
    
    var displayName: String {
        switch self {
        case .pickup: return String(localized: "ordering_mode_pickup")
        case .dineIn: return String(localized: "ordering_mode_dine_in")
        case .delivery: return String(localized: "ordering_mode_delivery")
        }
    }
    
    var iconName: String {
        switch self {
        case .pickup: return "bag.fill"
        case .dineIn: return "fork.knife"
        case .delivery: return "bicycle"
        }
    }
    
    var apiValue: String {
        switch self {
        case .pickup: return "take_away"
        case .dineIn: return "dine_in"
        case .delivery: return "delivery"
        }
    }
}

// MARK: - Payment Method

enum PaymentMethod: String, Codable, CaseIterable, Sendable {
    case applePay = "apple_pay"
    case cash
    case card
    case momo
    case zalopay
    
    var displayName: String {
        switch self {
        case .applePay: return String(localized: "payment_method_apple_pay")
        case .cash: return String(localized: "payment_method_cash")
        case .card: return String(localized: "payment_method_card")
        case .momo: return String(localized: "payment_method_momo")
        case .zalopay: return String(localized: "payment_method_zalopay")
        }
    }
    
    var iconName: String {
        switch self {
        case .applePay: return "applelogo"
        case .cash: return "banknote"
        case .card: return "creditcard"
        case .momo: return "m.circle.fill"
        case .zalopay: return "z.circle.fill"
        }
    }
    
    /// Valid payment methods for checkout - excludes cash (server rejects cash payments with 400 error)
    static var validForCheckout: [PaymentMethod] {
        [.applePay, .card, .momo, .zalopay]
    }
}

// MARK: - Order

struct Order: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let userId: String
    let storeId: String
    var status: OrderStatus
    let mode: OrderingMode
    let paymentMethod: PaymentMethod
    let items: [OrderItem]
    let subtotal: Double
    let deliveryFee: Double
    let discount: Double
    let totalAmount: Double
    let tableId: String?
    let deliveryAddress: DeliveryAddress?
    let deliveryNotes: String?
    let staffNotes: String?
    let createdAt: Date
    var updatedAt: Date
    let estimatedReadyAt: Date?
    let completedAt: Date?
    let cancelledAt: Date?
    let cancellationReason: String?
    let paymentUrl: String?
    // H2 FIX: Additional fields for price breakdown & receipt
    let tax: Double?
    let taxRate: Double?
    let pointsUsed: Int?
    let voucherSnapshot: VoucherSnapshot?
    let storeSnapshot: StoreSnapshot?
    
    var canUndo: Bool {
        guard status == .cancelled, let cancelledAt = cancelledAt else { return false }
        let undoWindow: TimeInterval = 30
        return Date().timeIntervalSince(cancelledAt) < undoWindow
    }
    
    var undoTimeRemaining: TimeInterval {
        guard let cancelledAt = cancelledAt else { return 0 }
        let undoWindow: TimeInterval = 30
        return max(0, undoWindow - Date().timeIntervalSince(cancelledAt))
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case storeId = "store_id"
        case status, mode
        case paymentMethod = "payment_method"
        case items, subtotal
        case deliveryFee = "delivery_fee"
        case discount
        case totalAmount = "total_amount"
        case tableId = "table_id"
        case deliveryAddress = "delivery_address"
        case deliveryNotes = "delivery_notes"
        case staffNotes = "staff_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case estimatedReadyAt = "estimated_ready_at"
        case completedAt = "completed_at"
        case cancelledAt = "cancelled_at"
        case cancellationReason = "cancellation_reason"
        case paymentUrl = "payment_url"
        case tax
        case taxRate = "tax_rate"
        case pointsUsed = "points_used"
        case voucherSnapshot = "voucher_snapshot"
        case storeSnapshot = "store_snapshot"
    }
    

}

// MARK: - Voucher Snapshot (H2)

struct VoucherSnapshot: Codable, Hashable, Sendable {
    let id: String?
    let code: String?
    let discountType: String?
    let discountAmount: Double?
    let maxDiscount: Double?
    let appliedDiscount: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, code
        case discountType = "discount_type"
        case discountAmount = "discount_amount"
        case maxDiscount = "max_discount"
        case appliedDiscount = "applied_discount"
    }
}

// MARK: - Store Snapshot (H2)

struct StoreSnapshot: Codable, Hashable, Sendable {
    let id: String?
    let name: String?
    let address: String?
    let phone: String?
}

// MARK: - Order Item

struct OrderItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let orderId: String
    let productId: String
    let productName: String
    let productImage: String?
    let quantity: Int
    let unitPrice: Double
    let finalPrice: Double
    let customization: OrderCustomization
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case productId = "product_id"
        case productName = "product_name"
        case productImage = "product_image"
        case quantity
        case unitPrice = "unit_price"
        case finalPrice = "final_price"
        case customization
    }
    
    var totalPrice: Double { finalPrice * Double(quantity) }
}

// MARK: - Order Customization

struct OrderCustomization: Codable, Hashable, Sendable {
    var size: ProductSize
    var sugar: SugarLevel?
    var ice: IceLevel?
    var toppings: [ToppingSelection]
    var notes: String?
    
    nonisolated init(size: ProductSize, sugar: SugarLevel? = nil, ice: IceLevel? = nil, toppings: [ToppingSelection] = [], notes: String? = nil) {
        self.size = size
        self.sugar = sugar
        self.ice = ice
        self.toppings = toppings
        self.notes = notes
    }
    
    nonisolated var toppingsTotal: Double {
        return toppings.reduce(0) { $0 + $1.price }
    }
    
    var displayText: String {
        var parts: [String] = [size.displayName]
        //if let size = size { parts.append(size.displayName) }
        if let sugar = sugar { parts.append(sugar.displayName) }
        if let ice = ice { parts.append(ice.displayName) }
        if !toppings.isEmpty { parts.append(String(localized: "customization_toppings_count \(toppings.count)")) }
        return parts.joined(separator: " • ")
    }
    
    static var `default`: OrderCustomization {
        OrderCustomization(size: .medium, sugar: .full, ice: .normal, toppings: [], notes: nil)
    }
}

// MARK: - Product Size

enum ProductSize: String, Codable, CaseIterable, Sendable {
    case small = "S"
    case medium = "M"
    case large = "L"
    
    var displayName: String {
        switch self {
        case .small: return String(localized: "size_small")
        case .medium: return String(localized: "size_medium")
        case .large: return String(localized: "size_large")
        }
    }
}

// MARK: - Sugar Level

enum SugarLevel: String, Codable, CaseIterable, Sendable {
    case none = "0%"
    case quarter = "25%"
    case half = "50%"
    case threeQuarter = "75%"
    case full = "100%"
    
    var displayName: String {
        switch self {
        case .none: return String(localized: "sugar_level_suffix 0%")
        case .quarter: return String(localized: "sugar_level_suffix 25%")
        case .half: return String(localized: "sugar_level_suffix 50%")
        case .threeQuarter: return String(localized: "sugar_level_suffix 75%")
        case .full: return String(localized: "sugar_level_suffix 100%")
        }
    }
}

// MARK: - Ice Level

enum IceLevel: String, Codable, CaseIterable, Sendable {
    case none = "no"
    case less = "less"
    case normal = "normal"
    case extra = "extra"
    
    var displayName: String {
        switch self {
        case .none: return String(localized: "ice_level_no")
        case .less: return String(localized: "ice_level_less")
        case .normal: return String(localized: "ice_level_normal")
        case .extra: return String(localized: "ice_level_extra")
        }
    }
}

// MARK: - Topping Selection

struct ToppingSelection: Codable, Hashable, Sendable {
    let id: String
    let name: String
    let price: Double
    let quantity: Int
    
    nonisolated init(id: String, name: String, price: Double, quantity: Int) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
    }
}

// MARK: - API Requests/Responses

struct CreateOrderRequest: Codable, Sendable {
    let storeId: String
    let mode: OrderingMode
    let paymentMethod: PaymentMethod
    let items: [CreateOrderItemRequest]
    let tableId: String?
    let deliveryAddressId: String?
    let deliveryNotes: String?
    let staffNotes: String?
    let voucherCode: String?
    let pointsToRedeem: Int?
    let totalAmount: Double
    let idempotencyKey: String? // C3: Prevent duplicate orders
    let memberTier: String? // H7: Membership tier for server-side discount validation
    
    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case mode = "delivery_option"
        case paymentMethod = "payment_method"
        case items
        case tableId = "table_id"
        case deliveryAddressId = "delivery_address_id"
        case deliveryNotes = "delivery_notes"
        case staffNotes = "staff_notes"
        case voucherCode = "voucher_code"
        case pointsToRedeem = "points_to_redeem"
        case totalAmount = "total_amount"
        case idempotencyKey = "idempotency_key"
        case memberTier = "member_tier"
    }
}

struct CreateOrderItemRequest: Codable, Sendable {
    let productId: String
    let productName: String
    let quantity: Int
    let finalPrice: Double
    let customization: OrderCustomization
    
    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case productName = "product_name"
        case quantity
        case finalPrice = "final_price"
        case customization
    }
}


struct OrderResponse: Codable, Sendable {
    let success: Bool
    let order: Order?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success, order, message
    }
}

// MARK: - Create Order Response (different structure from OrderResponse)
struct CreateOrderResponse: Codable, Sendable {
    let success: Bool
    let orderId: String
    let status: String
    let expiresAt: String?
    let estimatedReadyTime: String?
    let order: APICreateOrder
    let orderId2: String?  // API returns both "orderId" and "order_id"
    
    struct APICreateOrder: Codable {
        let id: String
        let user_id: String
        let store_id: String
        let voucher_id: String?
        let status: String
        let type: String
        let table_id: String?
        let total_amount: Double
        let discount: Double?
        let payment_method: String
        let payment_status: String
        let payment_token: String?
        let delivery_address: String?
        let delivery_lat: Double?
        let delivery_lng: Double?
        let delivery_notes: String?
        let notes: String?
        let created_at: String
        let updated_at: String
        let pending_until: String?
        let source: String
        let delivery_option: String
        let delivery_address_id: String?
        let delivery_fee: Double
        let delivery_eta_minutes: Int?
        let has_notes: Bool
        let finalized_at: String?
        let items: [APICreateOrderItem]
        let estimated_ready_at: String?
        let payment_url: String?
        
        struct APICreateOrderItem: Codable {
            let order_id: String
            let product_id: String
            let product_name: String
            let final_price: Double
            let quantity: Int
            let options_snapshot_json: APIOrderCustomization
            let notes: String?
            let is_favorite: Bool
            
            struct APIOrderCustomization: Codable {
                let ice: String?
                let size: String?
                let sugar: String?
                let toppings: [APIToppingSelection]?
                
                struct APIToppingSelection: Codable {
                    let id: String?
                    let name: String?
                    let price: Double?
                    let quantity: Int?
                }
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case success
        case orderId
        case status
        case expiresAt
        case estimatedReadyTime
        case order
        case orderId2 = "order_id"
    }
    
    func toOrder() -> Order {
        let apiOrder = self.order
        let orderStatus: OrderStatus = OrderStatus(rawValue: apiOrder.status) ?? .pending
        let orderingMode: OrderingMode = OrderingMode(rawValue: apiOrder.delivery_option) ?? .pickup
        let paymentMethod: PaymentMethod = PaymentMethod(rawValue: apiOrder.payment_method) ?? .cash
        
        let items = apiOrder.items.map { apiItem in
            // Parse size
            let size: ProductSize
            if let sizeStr = apiItem.options_snapshot_json.size?.uppercased() {
                size = ProductSize(rawValue: sizeStr) ?? .medium
            } else {
                size = .medium
            }
            
            // Parse sugar
            let sugar: SugarLevel?
            if let sugarStr = apiItem.options_snapshot_json.sugar {
                sugar = SugarLevel(rawValue: sugarStr)
            } else {
                sugar = .half
            }
            
            // Parse ice
            let ice: IceLevel?
            if let iceStr = apiItem.options_snapshot_json.ice {
                ice = IceLevel(rawValue: iceStr)
            } else {
                ice = .normal
            }
            
            // M7 FIX: Parse toppings from snapshot instead of always []
            let toppings: [ToppingSelection] = apiItem.options_snapshot_json.toppings?.compactMap { apiTopping in
                guard let id = apiTopping.id else { return nil }
                return ToppingSelection(
                    id: id,
                    name: apiTopping.name ?? "Topping",
                    price: apiTopping.price ?? 0,
                    quantity: apiTopping.quantity ?? 1
                )
            } ?? []
            
            let customization = OrderCustomization(
                size: size,
                sugar: sugar,
                ice: ice,
                toppings: toppings,
                notes: apiItem.notes
            )
            
            return OrderItem(
                id: UUID().uuidString,  // API doesn't return item ID in create response
                orderId: apiItem.order_id,
                productId: apiItem.product_id,
                productName: apiItem.product_name,
                productImage: nil,
                quantity: apiItem.quantity,
                unitPrice: apiItem.final_price,
                finalPrice: apiItem.final_price,
                customization: customization
            )
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let createdDate = dateFormatter.date(from: apiOrder.created_at) ?? Date()
        let updatedDate = dateFormatter.date(from: apiOrder.updated_at) ?? Date()
        let estimatedReadyDate = apiOrder.estimated_ready_at.flatMap { dateFormatter.date(from: $0) }
        
        // Calculate subtotal from items
        let subtotal = items.reduce(0.0) { $0 + ($1.finalPrice * Double($1.quantity)) }
        
        return Order(
            id: apiOrder.id,
            userId: apiOrder.user_id,
            storeId: apiOrder.store_id,
            status: orderStatus,
            mode: orderingMode,
            paymentMethod: paymentMethod,
            items: items,
            subtotal: subtotal,
            deliveryFee: apiOrder.delivery_fee,
            discount: apiOrder.discount ?? 0,  // Read discount from API response
            totalAmount: apiOrder.total_amount,
            tableId: apiOrder.table_id,
            deliveryAddress: nil,
            deliveryNotes: apiOrder.delivery_notes,
            staffNotes: apiOrder.notes,
            createdAt: createdDate,
            updatedAt: updatedDate,
            estimatedReadyAt: estimatedReadyDate,
            completedAt: orderStatus == .completed ? updatedDate : nil,
            cancelledAt: orderStatus == .cancelled ? updatedDate : nil,
            cancellationReason: nil,
            paymentUrl: apiOrder.payment_url,
            tax: nil,
            taxRate: nil,
            pointsUsed: nil,
            voucherSnapshot: nil,
            storeSnapshot: nil
        )
    }
}


struct OrdersListResponse: Codable, Sendable {
    let success: Bool
    let orders: [Order]
    let totalCount: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case success, orders
        case totalCount = "total_count"
        case hasMore = "has_more"
    }
}

// MARK: - API Response DTOs (matches actual API snake_case format)

struct APIOrdersResponse: Codable {
    let success: Bool
    let orders: [APIOrder]
    let totalCount: Int?
    let hasMore: Bool?
    
    enum CodingKeys: String, CodingKey {
        case success, orders
        case totalCount = "totalCount"
        case hasMore = "hasMore"
    }
    
    struct APIOrder: Codable {
        let id: String?
        let user_id: String?
        let store_id: String?
        let voucher_id: String?
        let status: String?
        let type: String?
        let table_id: String?
        let total_amount: Double?
        let discount: Double?
        let payment_method: String?
        let payment_status: String?
        let payment_token: String?
        let delivery_address: String?
        let delivery_lat: Double?
        let delivery_lng: Double?
        let delivery_notes: String?
        let notes: String?
        let created_at: String?
        let updated_at: String?
        let pending_until: String?
        let source: String?
        let delivery_option: String?
        let delivery_address_id: String?
        let delivery_fee: Double?
        let delivery_eta_minutes: Int?
        let has_notes: Bool?
        let finalized_at: String?
        let order_items: [APIOrderItem]?
        let payment_url: String?
        
        struct APIOrderItem: Codable {
            let id: String?
            let notes: String?
            let order_id: String?
            let quantity: Int?
            let created_at: String?
            let product_id: String?
            let final_price: Double?
            let is_favorite: Bool?
            let product_name: String?
            let product_image: String?
            let options_snapshot_json: APIOrderCustomization?
            
            struct APIOrderCustomization: Codable {
                let ice: String?
                let size: String?
                let sugar: String?
                let toppings: [APIToppingRef]?
                
                struct APIToppingRef: Codable {
                    let id: String?
                    let name: String?
                    let price: Double?
                    let quantity: Int?
                }
            }
        }
    }
    
    func toOrders() -> [Order] {
        return orders.compactMap { apiOrder -> Order? in
            guard let orderId = apiOrder.id else { return nil }
            
            let orderStatus: OrderStatus = OrderStatus(rawValue: apiOrder.status ?? "") ?? .pending
            let orderingMode: OrderingMode = OrderingMode(rawValue: apiOrder.delivery_option ?? "") ?? .pickup
            let paymentMethod: PaymentMethod = PaymentMethod(rawValue: apiOrder.payment_method ?? "") ?? .cash
            
            let items: [OrderItem]
            if let apiItems = apiOrder.order_items {
                items = apiItems.compactMap { apiItem -> OrderItem? in
                    guard let itemId = apiItem.id, let productId = apiItem.product_id else { return nil }
                    
                    // Parse size
                    let size: ProductSize
                    if let sizeStr = apiItem.options_snapshot_json?.size?.lowercased() {
                        size = sizeStr.contains("small") ? .small :
                               sizeStr.contains("large") ? .large : .medium
                    } else {
                        size = .medium
                    }
                    
                    // Parse sugar
                    let sugar: SugarLevel
                    if let sugarStr = apiItem.options_snapshot_json?.sugar {
                        if sugarStr.contains("0") { sugar = .none }
                        else if sugarStr.contains("25") { sugar = .quarter }
                        else if sugarStr.contains("50") { sugar = .half }
                        else if sugarStr.contains("75") { sugar = .threeQuarter }
                        else { sugar = .full }
                    } else {
                        sugar = .half
                    }
                    
                    // Parse ice
                    let ice: IceLevel
                    if let iceStr = apiItem.options_snapshot_json?.ice?.lowercased() {
                        if iceStr.contains("no") { ice = .none }
                        else if iceStr.contains("less") { ice = .less }
                        else if iceStr.contains("extra") { ice = .extra }
                        else { ice = .normal }
                    } else {
                        ice = .normal
                    }
                    
                    // M7 FIX: Parse toppings from snapshot
                    let toppings: [ToppingSelection] = apiItem.options_snapshot_json?.toppings?.compactMap { ref in
                        guard let id = ref.id else { return nil }
                        return ToppingSelection(id: id, name: ref.name ?? "Topping", price: ref.price ?? 0, quantity: ref.quantity ?? 1)
                    } ?? []
                    
                    let customization = OrderCustomization(
                        size: size,
                        sugar: sugar,
                        ice: ice,
                        toppings: toppings,
                        notes: apiItem.notes
                    )
                    
                    return OrderItem(
                        id: itemId,
                        orderId: apiItem.order_id ?? orderId,
                        productId: productId,
                        productName: apiItem.product_name ?? "Unknown Product",
                        productImage: apiItem.product_image,
                        quantity: apiItem.quantity ?? 1,
                        unitPrice: apiItem.final_price ?? 0,
                        finalPrice: apiItem.final_price ?? 0,
                        customization: customization
                    )
                }
            } else {
                items = []
            }
            
            let dateFormatter = ISO8601DateFormatter()
            let createdDate = dateFormatter.date(from: apiOrder.created_at ?? "") ?? Date()
            let updatedDate = dateFormatter.date(from: apiOrder.updated_at ?? "") ?? Date()
            
            // Safe unwrap values
            let deliveryFee = apiOrder.delivery_fee ?? 0.0
            let totalAmount = apiOrder.total_amount ?? 0.0
            let discount = apiOrder.discount ?? 0.0
            
            // FIX: Correct subtotal calculation accounting for tax, discount, and delivery
            // Server formula: total = (subtotal - discount) * (1 + taxRate) + deliveryFee
            // So: subtotal = items sum. We compute from items if available, else reverse-calculate.
            let subtotal = items.isEmpty 
                ? totalAmount - deliveryFee + discount
                : items.reduce(0.0) { $0 + ($1.finalPrice * Double($1.quantity)) }
            
            return Order(
                id: orderId,
                userId: apiOrder.user_id ?? "",
                storeId: apiOrder.store_id ?? "",
                status: orderStatus,
                mode: orderingMode,
                paymentMethod: paymentMethod,
                items: items,
                subtotal: subtotal,
                deliveryFee: deliveryFee,
                discount: apiOrder.discount ?? 0,
                totalAmount: totalAmount,
                tableId: apiOrder.table_id,
                deliveryAddress: nil,
                deliveryNotes: apiOrder.delivery_notes,
                staffNotes: apiOrder.notes,
                createdAt: createdDate,
                updatedAt: updatedDate,
                estimatedReadyAt: nil,
                completedAt: orderStatus == .completed ? updatedDate : nil,
                cancelledAt: orderStatus == .cancelled ? updatedDate : nil,
                cancellationReason: nil,
                paymentUrl: apiOrder.payment_token, // In APIOrdersResponse, payment_token might be used or we add payment_url
                tax: nil,
                taxRate: nil,
                pointsUsed: nil,
                voucherSnapshot: nil,
                storeSnapshot: nil
            )
        }
    }
}

struct CancelOrderRequest: Codable, Sendable {
    let orderId: String
    let reason: String?
}

struct UndoCancelRequest: Codable, Sendable {
    let orderId: String
}
