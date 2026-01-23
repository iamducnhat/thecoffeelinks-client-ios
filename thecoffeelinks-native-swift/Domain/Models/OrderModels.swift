//
//  OrderModels.swift
//  thecoffeelinks-native-swift
//
//  Domain models for orders - NO SwiftUI imports
//

import Foundation

// MARK: - Order Status Lifecycle

enum OrderStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case placed
    case preparing
    case ready
    case delivering
    case completed
    case cancelled
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .placed: return "Order Placed"
        case .preparing: return "Preparing"
        case .ready: return "Ready"
        case .delivering: return "On the Way"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .pending, .placed, .preparing, .ready, .delivering:
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
        case .pickup: return "Pickup"
        case .dineIn: return "Dine In"
        case .delivery: return "Delivery"
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
        case .applePay: return "Apple Pay"
        case .cash: return "Cash"
        case .card: return "Card"
        case .momo: return "MoMo"
        case .zalopay: return "ZaloPay"
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
    }
    
    static func == (lhs: Order, rhs: Order) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
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
    
    var toppingsTotal: Double {
        toppings.reduce(0) { $0 + $1.price }
    }
    
    var displayText: String {
        var parts: [String] = [size.displayName]
        if let sugar = sugar { parts.append(sugar.displayName) }
        if let ice = ice { parts.append(ice.displayName) }
        if !toppings.isEmpty { parts.append("+\(toppings.count) toppings") }
        return parts.joined(separator: " • ")
    }
    
    static var `default`: OrderCustomization {
        OrderCustomization(size: .medium, sugar: .half, ice: .normal, toppings: [], notes: nil)
    }
}

// MARK: - Product Size

enum ProductSize: String, Codable, CaseIterable, Sendable {
    case small = "S"
    case medium = "M"
    case large = "L"
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
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
    
    var displayName: String { rawValue + " Sugar" }
}

// MARK: - Ice Level

enum IceLevel: String, Codable, CaseIterable, Sendable {
    case none = "no"
    case less = "less"
    case normal = "normal"
    case extra = "extra"
    
    var displayName: String {
        switch self {
        case .none: return "No Ice"
        case .less: return "Less Ice"
        case .normal: return "Normal Ice"
        case .extra: return "Extra Ice"
        }
    }
}

// MARK: - Topping Selection

struct ToppingSelection: Codable, Hashable, Sendable {
    let id: String
    let name: String
    let price: Double
    let quantity: Int
}

// MARK: - API Requests/Responses

struct CreateOrderRequest: Codable, Sendable {
    let storeId: String
    let mode: OrderingMode
    // Server expects 'deliveryOption' or 'order_type'.
    // Mapped explicitly here.
    let paymentMethod: PaymentMethod
    let items: [CreateOrderItemRequest]
    let tableId: String?
    let deliveryAddressId: String?
    let deliveryNotes: String?
    let staffNotes: String?
    let voucherCode: String?
    let totalAmount: Double
    
    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case mode = "delivery_option" // Changed from 'deliveryOption' to 'delivery_option' or 'order_type' if server is snake_case? 
        // Note: Previous mapped "deliveryOption". If server uses snake_case, it might be "delivery_option".
        // HOWEVER, server code snippet (ref: APIOrder) shows "delivery_option".
        // Let's assume standard snake_case "delivery_option".
        case paymentMethod = "payment_method"
        case items
        case tableId = "table_id"
        case deliveryAddressId = "delivery_address_id"
        case deliveryNotes = "delivery_notes"
        case staffNotes = "staff_notes"
        case voucherCode = "voucher_code"
        case totalAmount = "total_amount"
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
                let toppings: [String]?
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
            
            let customization = OrderCustomization(
                size: size,
                sugar: sugar,
                ice: ice,
                toppings: [],
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
            discount: 0,  // API doesn't return discount in create response
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
            cancellationReason: nil
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
    
    struct APIOrder: Codable {
        let id: String?
        let user_id: String?
        let store_id: String?
        let voucher_id: String?
        let status: String?
        let type: String?
        let table_id: String?
        let total_amount: Double?
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
                let toppings: [String]?
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
                    
                    let customization = OrderCustomization(
                        size: size,
                        sugar: sugar,
                        ice: ice,
                        toppings: [],
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
            
            // Calculate subtotal if not provided logic:
            // subtotal = total - fee.
            let subtotal = totalAmount - deliveryFee
            
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
                discount: 0,
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
                cancellationReason: nil
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
