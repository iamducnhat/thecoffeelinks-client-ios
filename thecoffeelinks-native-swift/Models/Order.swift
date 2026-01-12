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
struct Order: Decodable, Identifiable {
    let id: String
    let userId: String?
    let status: OrderStatus?
    let totalAmount: Double?
    let discountAmount: Double?
    let paymentMethod: PaymentMethod?
    let type: DeliveryOption?
    let tableQrCode: String?
    let createdAt: String?
    let storeId: String?
    let deliveryAddress: String?
    let deliveryLatitude: Double?
    let deliveryLongitude: Double?
    let deliveryNotes: String?
    
    // Computed properties for UI compatibility
    var total: Double { totalAmount ?? 0 }
    var deliveryOption: DeliveryOption { type ?? .takeAway }
    
    // Order items (nested from API select: *, order_items(*))
    let orderItems: [OrderItem]?
}

struct OrderItem: Decodable, Identifiable {
    let id: String
    let productId: String?
    let quantity: Int?
    let price: Double?
}
