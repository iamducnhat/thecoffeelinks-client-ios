import Foundation

enum OrderStatus: String, Codable {
    case placed
    case ready
    case completed
    case cancelled
}

enum DeliveryOption: String, Codable {
    case dineIn = "dine_in"
    case takeAway = "take_away"
    case delivery = "delivery"
}

enum PaymentMethod: String, Codable {
    case cash
    case card
    case momo
    case zalopay
}

/// Order model - API returns snake_case, but APIClient uses .convertFromSnakeCase
/// So we DON'T need CodingKeys - just use camelCase property names
// Order model
struct Order: Decodable, Identifiable, Hashable {
    let id: String
    let userId: String?
    let status: String? // "received", "preparing", ...
    let totalAmount: Double?
    let type: String // "dine_in", "take_away"
    let tableId: String? // Mapped from table_id
    let createdAt: String?
    let deliveryAddress: String? // Restored for compatibility
    
    // Nested items
    let orderItems: [OrderItem]?
    
    // Helpers
    var items: [OrderItem] { orderItems ?? [] }
    
    var deliveryOption: DeliveryOption {
        switch type {
        case "dine_in": return .dineIn
        case "delivery": return .delivery
        default: return .takeAway
        }
    }
    
    var total: Double { totalAmount ?? 0 }
    
    // Equatable/Hashable conformance
    static func == (lhs: Order, rhs: Order) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct OrderItem: Decodable, Identifiable, Hashable {
    let id: String // UUID or Int depending on DB
    let orderId: String?
    let productId: String? // Restored
    let productName: String // Mapped from product_name
    let quantity: Int
    let finalPrice: Double?
    // customization is stored as options_snapshot_json in DB.
    let optionsSnapshotJson: OrderCustomization? 
}
