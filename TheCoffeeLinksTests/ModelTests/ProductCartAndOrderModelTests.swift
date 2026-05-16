import XCTest
@testable import TheCoffeeLinks

@MainActor
final class ProductCartAndOrderModelTests: XCTestCase {
    func testProductPricingUsesSelectedSizeAndStoreAvailability() {
        let product = TestFactory.product(basePrice: 68_000, isStoreAvailable: true)

        XCTAssertEqual(product.price(for: .small), 60_000)
        XCTAssertEqual(product.price(for: .medium), 68_000)
        XCTAssertEqual(product.price(for: .large), 78_000)
        XCTAssertTrue(product.isAvailableAt(storeId: "store-d1"))
        XCTAssertTrue(product.canBeDelivered)
    }

    func testSoldOutStoreOverrideBlocksCheckoutAvailability() {
        let product = TestFactory.product(isStoreAvailable: false)

        XCTAssertFalse(product.isAvailableAt(storeId: "store-d1"))
        XCTAssertTrue(product.isSoldOut)
    }

    func testCartMergesIdenticalCustomizedItemsAndCalculatesSubtotal() {
        let product = TestFactory.product(basePrice: 45_000)
        let customization = TestFactory.customization(toppings: [TestFactory.topping(price: 10_000)])
        let item = TestFactory.cartItem(product: product, quantity: 1, storeId: "store-d1", customization: customization)
        var cart = Cart.empty

        cart.storeId = "store-d1"
        cart.addItem(item)
        cart.addItem(item)

        XCTAssertEqual(cart.uniqueItemCount, 1)
        XCTAssertEqual(cart.itemCount, 2)
        XCTAssertEqual(cart.subtotal, 110_000)
    }

    func testCartItemKeyIsStableWhenToppingsAreReordered() {
        let product = TestFactory.product()
        let first = TestFactory.customization(toppings: [
            TestFactory.topping(id: "b", price: 5_000),
            TestFactory.topping(id: "a", price: 5_000)
        ])
        let second = TestFactory.customization(toppings: [
            TestFactory.topping(id: "a", price: 5_000),
            TestFactory.topping(id: "b", price: 5_000)
        ])

        let firstKey = CartItem.generateKey(product: product, modifiers: first, priceSnapshot: 78_000, storeId: "store-d1")
        let secondKey = CartItem.generateKey(product: product, modifiers: second, priceSnapshot: 78_000, storeId: "store-d1")

        XCTAssertEqual(firstKey, secondKey)
    }

    func testCreateOrderRequestEncodesServerContract() throws {
        let request = CreateOrderRequest(
            storeId: "store-d1",
            mode: .pickup,
            paymentMethod: .card,
            items: [CreateOrderItemRequest(productId: "prod-1", productName: "Den Phin", quantity: 2, finalPrice: 45_000, customization: .default)],
            tableId: nil,
            deliveryAddressId: nil,
            deliveryNotes: "Nhanh giup minh",
            staffNotes: "It da",
            voucherCode: "WELCOME",
            pointsToRedeem: 10,
            totalAmount: 90_000,
            idempotencyKey: "idem-1",
            memberTier: nil
        )

        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        XCTAssertEqual(object?["store_id"] as? String, "store-d1")
        XCTAssertEqual(object?["delivery_option"] as? String, "pickup")
        XCTAssertEqual(object?["payment_method"] as? String, "card")
        XCTAssertEqual(object?["points_to_redeem"] as? Int, 10)
        XCTAssertEqual(object?["idempotency_key"] as? String, "idem-1")
    }

    func testCreateOrderResponseDecodesProductionShapeForCheckout() throws {
        let json = """
        {
          "success": true,
          "orderId": "order-1",
          "order_id": "order-1",
          "status": "placed",
          "expiresAt": "2026-05-15T15:03:36.054Z",
          "estimatedReadyTime": "2026-05-15T15:18:07.508Z",
          "paymentUrl": "https://sandbox.vnpayment.vn/pay",
          "order": {
            "id": "order-1",
            "user_id": "",
            "store_id": "store-d1",
            "voucher_id": null,
            "status": "placed",
            "type": "take_away",
            "table_id": null,
            "total_amount": 1242000,
            "discount": 0,
            "payment_method": "zalopay",
            "payment_status": "pending",
            "payment_token": null,
            "delivery_address": null,
            "delivery_lat": null,
            "delivery_lng": null,
            "delivery_notes": null,
            "notes": null,
            "created_at": "2026-05-15T15:03:07Z",
            "updated_at": "2026-05-15T15:03:07Z",
            "pending_until": "2026-05-15T15:03:36Z",
            "source": "manual",
            "delivery_option": "pickup",
            "delivery_address_id": null,
            "delivery_fee": 0,
            "delivery_eta_minutes": null,
            "has_notes": false,
            "finalized_at": null,
            "estimated_ready_at": "2026-05-15T15:18:07Z",
            "payment_url": "https://sandbox.vnpayment.vn/pay",
            "tax": 92000,
            "tax_rate": 0.08,
            "points_used": 0,
            "voucher_snapshot": null,
            "store_snapshot": { "id": "store-d1", "name": "District 1", "address": "123 Nguyen Hue", "phone": null },
            "items": [
              {
                "order_id": "order-1",
                "product_id": "prod-1",
                "product_name": "Den Phin",
                "final_price": 45000,
                "quantity": 2,
                "options_snapshot_json": { "size": "M", "sugar": "100%", "ice": "normal", "toppings": [] },
                "notes": null,
                "is_favorite": false
              }
            ]
          }
        }
        """

        let response = try JSONDecoder().decode(CreateOrderResponse.self, from: Data(json.utf8))
        let order = response.toOrder()

        XCTAssertEqual(order.id, "order-1")
        XCTAssertEqual(order.userId, "")
        XCTAssertEqual(order.items.first?.orderId, "order-1")
        XCTAssertEqual(order.paymentMethod, .zalopay)
        XCTAssertEqual(order.paymentUrl, "https://sandbox.vnpayment.vn/pay")
    }
}
