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

struct Order: Codable, Identifiable {
    let id: String
    let userId: String?
    let status: OrderStatus
    let totalAmount: Double
    let discountAmount: Double?
    let paymentMethod: PaymentMethod?
    let type: DeliveryOption?
    let tableQrCode: String?
    let createdAt: String // Keep as String for simplicity; can parse to Date later
    let storeId: String?
    let deliveryAddress: String?
    let deliveryLatitude: Double?
    let deliveryLongitude: Double?
    let deliveryNotes: String?
    
    // Computed properties for UI compatibility
    var total: Double { totalAmount }
    var deliveryOption: DeliveryOption { type ?? .takeAway }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case totalAmount = "total_amount"
        case discountAmount = "discount_amount"
        case paymentMethod = "payment_method"
        case type
        case tableQrCode = "table_qr_code"
        case createdAt = "created_at"
        case storeId = "store_id"
        case deliveryAddress = "delivery_address"
        case deliveryLatitude = "delivery_latitude"
        case deliveryLongitude = "delivery_longitude"
        case deliveryNotes = "delivery_notes"
    }
}

