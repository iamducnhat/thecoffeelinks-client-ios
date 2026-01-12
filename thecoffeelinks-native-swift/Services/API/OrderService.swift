import Foundation

// MARK: - API Response Wrappers

struct OrdersResponse: Decodable {
    let orders: [Order]?
    let data: [Order]?
    let success: Bool?
    let error: String?
    
    var items: [Order] {
        orders ?? data ?? []
    }
}

struct SingleOrderResponse: Decodable {
    let order: Order?
    let success: Bool?
    let error: String?
}

// MARK: - OrderService

class OrderService: OrderServiceProtocol {
    private let apiClient = APIClient.shared
    
    func getOrders() async throws -> [Order] {
        let response: OrdersResponse = try await apiClient.get("/api/user/orders")
        return response.items
    }
    
    func getActiveOrders() async throws -> [Order] {
        let orders = try await getOrders()
        return orders.filter { $0.status == .placed || $0.status == .ready }
    }
    
    func createOrder(order: Order) async throws -> Order {
        struct CreateOrderRequest: Encodable {
            let type: String
            let totalAmount: Double
            let storeId: String?
            let deliveryAddress: String?
            let deliveryNotes: String?
            let paymentMethod: String?
        }
        
        let request = CreateOrderRequest(
            type: order.deliveryOption.rawValue,
            totalAmount: order.total,
            storeId: order.storeId,
            deliveryAddress: order.deliveryAddress,
            deliveryNotes: order.deliveryNotes,
            paymentMethod: order.paymentMethod?.rawValue
        )
        
        let response: SingleOrderResponse = try await apiClient.post("/api/orders", body: request)
        guard let createdOrder = response.order else {
            throw APIClient.APIError.invalidResponse
        }
        return createdOrder
    }
}
