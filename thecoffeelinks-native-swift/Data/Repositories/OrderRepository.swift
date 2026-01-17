//
//  OrderRepository.swift
//  thecoffeelinks-native-swift
//

import Foundation

final class OrderRepository: OrderRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func createOrder(_ request: CreateOrderRequest) async throws -> Order {
        let response: OrderResponse = try await networkService.post("/api/orders", body: request)
        guard let order = response.order else { throw OrderError.creationFailed(response.message ?? "Failed to create order") }
        return order
    }
    
    func getOrder(id: String) async throws -> Order {
        // SERVER MISSING ENDPOINT /api/orders/:id
        // WORKAROUND: Fetch all and filter
        let allOrdersResponse = try await getOrders(status: nil, limit: 100, offset: 0)
        guard let order = allOrdersResponse.orders.first(where: { $0.id == id }) else {
            throw OrderError.notFound
        }
        return order
    }
    
    func getOrders(status: OrderStatus?, limit: Int, offset: Int) async throws -> OrdersListResponse {
        var queryItems = [URLQueryItem(name: "limit", value: String(limit)), URLQueryItem(name: "offset", value: String(offset))]
        if let status = status { queryItems.append(URLQueryItem(name: "status", value: status.rawValue)) }
        
        // API returns snake_case format
        // NOTE: Server GET /api/orders ignores params and returns all orders.
        // We might get too much data, but we process what we get.
        let apiResponse: APIOrdersResponse = try await networkService.get("/api/orders", queryItems: queryItems)
        
        var orders = apiResponse.toOrders()
        
        // Client-side filtering because server ignores status param
        if let status = status {
            orders = orders.filter { $0.status == status }
        }
        
        return OrdersListResponse(
            success: apiResponse.success,
            orders: orders,
            totalCount: orders.count,
            hasMore: false
        )
    }
    
    func getActiveOrders() async throws -> [Order] {
        // SERVER MISSING ENDPOINT /api/orders/active
        // WORKAROUND: Fetch all and filter for active status
        let response = try await getOrders(status: nil, limit: 100, offset: 0)
        return response.orders.filter { $0.status.isActive }
    }
    
    func cancelOrder(id: String, reason: String?) async throws -> Order {
        let request = CancelOrderRequest(orderId: id, reason: reason)
        // Server returns { success: true, refundInitiated: Bool } but NO order object.
        // We cannot decode 'OrderResponse' expecting an order.
        struct CancelResponse: Decodable {
            let success: Bool
            let error: String?
        }
        
        let _: CancelResponse = try await networkService.post("/api/orders/\(id)/cancel", body: request)
        
        // Return updated order by fetching it again (inefficient but necessary)
        // Or construct a fake cancelled order if we had the original?
        // Let's fetch it.
        return try await getOrder(id: id)
    }
    
    func undoCancelOrder(id: String) async throws -> Order {
        struct UndoResponse: Decodable {
            let success: Bool
            let order: Order?
            let message: String?
            let error: String?
        }
        
        let response: UndoResponse = try await networkService.post("/api/orders/\(id)/undo-cancel", body: EmptyBody())
        
        if let order = response.order {
            return order
        } else if let error = response.error {
            throw OrderError.undoFailed(error)
        } else {
            throw OrderError.undoFailed(response.message ?? "Failed to restore order")
        }
    }
}

private struct EmptyBody: Encodable {}

enum OrderError: LocalizedError {
    case creationFailed(String), notFound, cancellationFailed(String), undoFailed(String), undoExpired
    var errorDescription: String? {
        switch self {
        case .creationFailed(let msg): return msg
        case .notFound: return "Order not found"
        case .cancellationFailed(let msg): return msg
        case .undoFailed(let msg): return msg
        case .undoExpired: return "Undo window has expired"
        }
    }
}
