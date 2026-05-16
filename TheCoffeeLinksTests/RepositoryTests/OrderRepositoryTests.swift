import XCTest
@testable import TheCoffeeLinks

@MainActor
final class OrderRepositoryTests: XCTestCase {
    func testCreateOrderPostsToOrdersEndpointAndMapsPaymentUrl() async throws {
        let network = MockNetworkService()
        network.registerJSON(Self.createOrderJSON, for: "POST", endpoint: "/api/orders")
        let repository = OrderRepository(networkService: network)
        let request = CreateOrderRequest(
            storeId: "store-d1",
            mode: .pickup,
            paymentMethod: .card,
            items: [CreateOrderItemRequest(productId: "prod-1", productName: "Espresso", quantity: 1, finalPrice: 68_000, customization: .default)],
            tableId: nil,
            deliveryAddressId: nil,
            deliveryNotes: nil,
            staffNotes: nil,
            voucherCode: nil,
            pointsToRedeem: 0,
            totalAmount: 68_000,
            idempotencyKey: "idem-1",
            memberTier: nil
        )

        let order = try await repository.createOrder(request)

        XCTAssertEqual(network.requests.first?.method, "POST")
        XCTAssertEqual(network.requests.first?.endpoint, "/api/orders")
        XCTAssertEqual(order.id, "order-1")
        XCTAssertEqual(order.items.first?.productName, "Espresso")
        XCTAssertEqual(order.paymentUrl, "https://sandbox.vnpayment.vn/pay")
    }

    private static let createOrderJSON = """
    {
      "success": true,
      "orderId": "order-1",
      "order_id": "order-1",
      "status": "placed",
      "expiresAt": null,
      "estimatedReadyTime": null,
      "paymentUrl": "https://sandbox.vnpayment.vn/pay",
      "order": {
        "id": "order-1",
        "user_id": "user-1",
        "store_id": "store-d1",
        "voucher_id": null,
        "status": "placed",
        "type": "take_away",
        "table_id": null,
        "total_amount": 73440,
        "discount": 0,
        "payment_method": "card",
        "payment_status": "pending",
        "payment_token": null,
        "delivery_address": null,
        "delivery_lat": null,
        "delivery_lng": null,
        "delivery_notes": null,
        "notes": null,
        "created_at": "2026-05-15T15:03:07Z",
        "updated_at": "2026-05-15T15:03:07Z",
        "pending_until": null,
        "source": "manual",
        "delivery_option": "pickup",
        "delivery_address_id": null,
        "delivery_fee": 0,
        "delivery_eta_minutes": null,
        "has_notes": false,
        "finalized_at": null,
        "estimated_ready_at": null,
        "payment_url": "https://sandbox.vnpayment.vn/pay",
        "tax": 5440,
        "tax_rate": 0.08,
        "points_used": 0,
        "voucher_snapshot": null,
        "store_snapshot": null,
        "items": [
          {
            "order_id": "order-1",
            "product_id": "prod-1",
            "product_name": "Espresso",
            "final_price": 68000,
            "quantity": 1,
            "options_snapshot_json": { "size": "M", "sugar": "100%", "ice": "normal", "toppings": [] },
            "notes": null,
            "is_favorite": false
          }
        ]
      }
    }
    """
}
