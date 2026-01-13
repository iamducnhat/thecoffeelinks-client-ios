import Foundation
import Supabase

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
        // Status is now String. Valid statuses: received, preparing, ready.
        return orders.filter { 
            let s = $0.status ?? ""
            return s == "received" || s == "preparing" || s == "ready" || s == "placed"
        }
    }
    
    func createOrder(items: [CartItem], total: Double, deliveryOption: DeliveryOption, storeId: String?, deliveryAddress: String?, deliveryNotes: String?, paymentMethod: PaymentMethod, paymentToken: String) async throws -> Order {
        
        // Match server expected payload structure
        struct CreateOrderRequest: Encodable {
            struct ItemPayload: Encodable {
                let product: Product
                let quantity: Int
                let finalPrice: Double
                let customization: OrderCustomization
            }
            
            let items: [ItemPayload]
            let deliveryOption: String
            let total: Double
            let user_id: String?
            let paymentToken: String
            let paymentMethod: String
            let storeId: String?
            let deliveryAddress: String?
            let deliveryLat: Double?
            let deliveryLng: Double?
            let deliveryNotes: String?
        }
        
        let itemPayloads = items.map { item in
            CreateOrderRequest.ItemPayload(
                product: item.product,
                quantity: item.quantity,
                finalPrice: item.finalPrice,
                customization: item.customization
            )
        }
        
        let request = CreateOrderRequest(
            items: itemPayloads,
            deliveryOption: deliveryOption.rawValue,
            total: total,
            user_id: AuthManager.shared.session?.userId,
            paymentToken: paymentToken,
            paymentMethod: paymentMethod.rawValue,
            storeId: storeId,
            deliveryAddress: deliveryAddress,
            deliveryLat: nil, // TODO: Add lat/lng support if needed
            deliveryLng: nil,
            deliveryNotes: deliveryNotes
        )
        
        let response: SingleOrderResponse = try await apiClient.post("/api/orders", body: request)
        guard let createdOrder = response.order else {
            throw APIClient.APIError.invalidResponse
        }
        return createdOrder
    }
    
    func verifyPayment(amount: Double, paymentMethod: String, storeId: String?, items: [CartItem]) async throws -> String {
        struct VerifyPaymentRequest: Encodable {
            let amount: Double
            let paymentMethod: String
            let storeId: String?
            let items: [CartItem]
        }
        
        struct VerifyPaymentResponse: Decodable {
            let success: Bool
            let payment: PaymentData?
            let error: String?
            
            struct PaymentData: Decodable {
                let token: String
            }
        }
        
        let request = VerifyPaymentRequest(
            amount: amount,
            paymentMethod: paymentMethod,
            storeId: storeId,
            items: items
        )
        
        let response: VerifyPaymentResponse = try await apiClient.post("/api/payments/verify", body: request)
        
        guard response.success, let token = response.payment?.token else {
            throw APIClient.APIError.invalidResponse // Or a specific payment error
        }
        
        return token
    }
    
    // MARK: - Realtime
    
    func subscribeToOrders(userId: String, onChange: @escaping () -> Void) async -> RealtimeChannelV2 {
        let channel = SupabaseManager.shared.client.channel("public:orders:\(userId)")
        
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "orders",
            filter: "user_id=eq.\(userId)"
        )
        
        await channel.subscribe()
        
        Task {
            for await _ in changes {
                onChange()
            }
        }
        
        return channel
    }
}
