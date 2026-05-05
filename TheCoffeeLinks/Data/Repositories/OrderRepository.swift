//
//  OrderRepository.swift
//  thecoffeelinks-client-ios
//

import Foundation

final class OrderRepository: OrderRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func createOrder(_ request: CreateOrderRequest) async throws -> Order {
        let response: CreateOrderResponse = try await networkService.post("/api/orders", body: request)
        return response.toOrder()
    }
    
    func getOrder(id: String) async throws -> Order {
        // Use dedicated endpoint for single order
        let response: OrderResponse = try await networkService.get("/api/orders/\(id)", queryItems: nil)
        guard let order = response.order else {
            throw OrderError.notFound
        }
        return order
    }
    
    func getOrders(status: OrderStatus?, limit: Int, offset: Int) async throws -> OrdersListResponse {
        var queryItems = [URLQueryItem(name: "limit", value: String(limit)), URLQueryItem(name: "offset", value: String(offset))]
        if let status = status { queryItems.append(URLQueryItem(name: "status", value: status.rawValue)) }
        
        // Use standardized API response model
        let apiResponse: APIOrderResponse = try await networkService.get("/api/orders", queryItems: queryItems)
        
        var orders = apiResponse.toOrders()
        
        // Client-side filtering because server ignores status param
        if let status = status {
            orders = orders.filter { $0.status == status }
        }
        
        return OrdersListResponse(
            success: apiResponse.success,
            orders: orders,
            totalCount: apiResponse.totalCount ?? orders.count, // Use server count if available
            hasMore: apiResponse.hasMore ?? false
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

    func reportOrderIssue(id: String, category: String, subject: String, description: String?) async throws {
        struct IncidentRequest: Encodable {
            let orderId: String
            let category: String
            let subject: String
            let description: String?
        }
        struct IncidentResponse: Decodable {
            let success: Bool
        }

        let _: IncidentResponse = try await networkService.post(
            "/api/support/incidents",
            body: IncidentRequest(orderId: id, category: category, subject: subject, description: description)
        )
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
