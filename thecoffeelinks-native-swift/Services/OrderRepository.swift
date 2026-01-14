import Foundation
import Combine

struct OrderPreviewRequest: Encodable {
    let productId: String
    let size: String
    let ice: String?
    let sugar: String?
    let toppings: [String]
    let quantity: Int
    let voucherId: String?
    
    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case size
        case ice
        case sugar
        case toppings
        case quantity
        case voucherId = "voucher_id"
    }
}

struct OrderPreviewResponse: Decodable {
    let subtotal: Double
    let discount: Double
    let tax: Double
    let total: Double
}

class OrderRepository: ObservableObject {
    static let shared = OrderRepository()
    
    private let client = APIClient.shared
    
    // Cache or state for last preview could be useful, but View usually manages state. 
    // This is a stateless service for now.
    
    func previewPrice(request: OrderPreviewRequest) async throws -> OrderPreviewResponse {
        // Debug: Log request
        if let jsonData = try? JSONEncoder().encode(request),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("DEBUG OrderPreview Request: \(jsonString)")
        }
        return try await client.post("api/orders/preview", body: request)
    }
    
    // Create order logic
    func createOrder(items: [CartItem], total: Double, type: String, tableId: String? = nil, paymentMethod: String) async throws -> String {
        let request = CreateOrderRequest(
            items: items,
            order_type: type,
            total_amount: total,
            table_id: tableId,
            payment_method: paymentMethod
        )
        
        let response: CreateOrderResponse = try await client.post("api/orders", body: request)
        return response.order_id
    }
}

// Request Models
struct CreateOrderRequest: Encodable {
    let items: [CartItem]
    let order_type: String
    let total_amount: Double
    let table_id: String?
    let payment_method: String
    // Add user_id if needed, but usually derived from Auth Header on server or passed here
}

struct CreateOrderResponse: Decodable {
    let success: Bool
    let order_id: String
    let status: String
    let estimated_ready_at: String
}
