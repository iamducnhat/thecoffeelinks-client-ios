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

    func testGetActiveOrdersUsesDedicatedEndpoint() async throws {
        let network = MockNetworkService()
        network.registerJSON(Self.ordersListJSON, for: "GET", endpoint: "/api/orders/active")
        let repository = OrderRepository(networkService: network)

        let orders = try await repository.getActiveOrders()

        XCTAssertEqual(network.requests.first?.method, "GET")
        XCTAssertEqual(network.requests.first?.endpoint, "/api/orders/active")
        XCTAssertEqual(orders.map(\.id), ["order-active-1"])
    }

    func testGetOrderCountUsesUserStatsEndpoint() async throws {
        let network = MockNetworkService()
        network.registerJSON(#"{ "success": true, "stats": { "orderCount": 42, "activeOrderCount": 1 } }"#, for: "GET", endpoint: "/api/user/stats")
        let repository = OrderRepository(networkService: network)

        let count = try await repository.getOrderCount()

        XCTAssertEqual(network.requests.first?.method, "GET")
        XCTAssertEqual(network.requests.first?.endpoint, "/api/user/stats")
        XCTAssertEqual(count, 42)
    }

    func testCacheServicePersistsDiskPayloadAndExpiresTTL() async throws {
        let writer = CacheService()
        await writer.clear()
        await writer.set("order_repository_cache_ttl_test", value: "fresh", ttl: 60)

        let reader = CacheService()
        let persisted: String? = await reader.get("order_repository_cache_ttl_test")
        XCTAssertEqual(persisted, "fresh")

        await writer.set("order_repository_cache_expired_test", value: "stale", ttl: -1)
        let expired: String? = await CacheService().get("order_repository_cache_expired_test")
        XCTAssertNil(expired)

        await reader.clear()
    }

    func testSyncManagerThrottlesRepeatedForegroundSyncs() async throws {
        let repository = MockSyncRepository(versions: ["menu": 1])
        let suiteName = "SyncManagerThrottleTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let manager = SyncManager(syncRepository: repository, userDefaults: defaults, keychainManager: nil)
        let domain = CountingSyncDomain(domainKey: "menu")

        manager.register(domain: domain)
        try await Task.sleep(nanoseconds: 100_000_000)
        let callsAfterLaunch = await repository.callCount

        await manager.triggerSync(reason: .foreground)
        await manager.triggerSync(reason: .foreground)

        let callsAfterForeground = await repository.callCount
        XCTAssertEqual(callsAfterForeground, callsAfterLaunch)
        XCTAssertEqual(domain.syncCount, 1)

        defaults.removePersistentDomain(forName: suiteName)
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

    private static let ordersListJSON = """
    {
      "success": true,
      "orders": [
        {
          "id": "order-active-1",
          "user_id": "user-1",
          "store_id": "store-d1",
          "status": "placed",
          "type": "take_away",
          "delivery_option": "pickup",
          "payment_method": "card",
          "payment_status": "pending",
          "total_amount": 73440,
          "discount": 0,
          "delivery_fee": 0,
          "table_id": null,
          "delivery_address_id": null,
          "delivery_address": null,
          "notes": null,
          "delivery_notes": null,
          "created_at": "2026-05-15T15:03:07Z",
          "updated_at": "2026-05-15T15:03:07Z",
          "estimated_ready_at": null,
          "completed_at": null,
          "cancelled_at": null,
          "cancellation_reason": null,
          "pending_until": null,
          "tax": 5440,
          "tax_rate": 0.08,
          "points_used": 0,
          "voucher_snapshot": null,
          "store_snapshot": null,
          "items": [
            {
              "id": "item-1",
              "order_id": "order-active-1",
              "product_id": "prod-1",
              "product_name": "Espresso",
              "final_price": 68000,
              "quantity": 1,
              "options_snapshot_json": { "size": "M", "sugar": "100%", "ice": "normal", "toppings": [] }
            }
          ]
        }
      ],
      "totalCount": 1,
      "hasMore": false
    }
    """
}

private actor MockSyncRepository: SyncRepositoryProtocol {
    private let versions: [String: Int]
    private(set) var callCount = 0

    init(versions: [String: Int]) {
        self.versions = versions
    }

    func getVersions() async throws -> [String: Int] {
        callCount += 1
        return versions
    }
}

private final class CountingSyncDomain: SyncableDomain, @unchecked Sendable {
    nonisolated let domainKey: String
    private let lock = NSLock()
    private var _syncCount = 0

    init(domainKey: String) {
        self.domainKey = domainKey
    }

    var syncCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _syncCount
    }

    func sync(reason: SyncReason) async {
        lock.lock()
        _syncCount += 1
        lock.unlock()
    }
}
