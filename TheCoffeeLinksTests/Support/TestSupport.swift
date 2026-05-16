import Foundation
@testable import TheCoffeeLinks

final class MockNetworkService: NetworkServiceProtocol, @unchecked Sendable {
    struct Request: Sendable {
        let method: String
        let endpoint: String
        let bodyData: Data?
    }

    private let lock = NSLock()
    private var responses: [String: Data] = [:]
    private var errors: [String: Error] = [:]
    private(set) var requests: [Request] = []

    func register<T: Encodable>(_ value: T, for method: String, endpoint: String, encoder: JSONEncoder = JSONEncoder()) throws {
        responses[key(method, endpoint)] = try encoder.encode(value)
    }

    func registerJSON(_ json: String, for method: String, endpoint: String) {
        responses[key(method, endpoint)] = Data(json.utf8)
    }

    func registerError(_ error: Error, for method: String, endpoint: String) {
        errors[key(method, endpoint)] = error
    }

    func get<T: Decodable>(_ endpoint: String, queryItems: [URLQueryItem]?) async throws -> T {
        try decode(method: "GET", endpoint: endpoint, body: Optional<Int>.none)
    }

    func post<T: Decodable, U: Encodable>(_ endpoint: String, body: U, encoder: JSONEncoder?) async throws -> T {
        try decode(method: "POST", endpoint: endpoint, body: body, encoder: encoder)
    }

    func put<T: Decodable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        try decode(method: "PUT", endpoint: endpoint, body: body)
    }

    func patch<T: Decodable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        try decode(method: "PATCH", endpoint: endpoint, body: body)
    }

    func delete(_ endpoint: String, queryItems: [URLQueryItem]?) async throws {
        record(method: "DELETE", endpoint: endpoint, bodyData: nil)
        if let error = errors[key("DELETE", endpoint)] { throw error }
    }

    private func decode<T: Decodable, U: Encodable>(method: String, endpoint: String, body: U, encoder: JSONEncoder? = nil) throws -> T {
        let bodyData: Data?
        if U.self == Optional<Int>.self {
            bodyData = nil
        } else {
            bodyData = try (encoder ?? JSONEncoder()).encode(body)
        }
        record(method: method, endpoint: endpoint, bodyData: bodyData)
        let requestKey = key(method, endpoint)
        if let error = errors[requestKey] { throw error }
        guard let data = responses[requestKey] else { throw TestError.missingMockResponse(method: method, endpoint: endpoint) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func record(method: String, endpoint: String, bodyData: Data?) {
        lock.lock()
        requests.append(Request(method: method, endpoint: endpoint, bodyData: bodyData))
        lock.unlock()
    }

    private func key(_ method: String, _ endpoint: String) -> String { "\(method) \(endpoint)" }
}

enum TestError: Error, Equatable {
    case missingMockResponse(method: String, endpoint: String)
    case requestedFailure
}

final class MockOrderRepository: OrderRepositoryProtocol, @unchecked Sendable {
    var createResult: Result<Order, Error>
    var getOrderResult: Result<Order, Error>
    private(set) var createdRequests: [CreateOrderRequest] = []
    private(set) var cancelledOrderIds: [String] = []
    private(set) var reportedIssues: [(String, String, String, String?)] = []

    @MainActor
    convenience init() {
        self.init(order: TestFactory.order())
    }

    init(order: Order) {
        self.createResult = .success(order)
        self.getOrderResult = .success(order)
    }

    func createOrder(_ request: CreateOrderRequest) async throws -> Order {
        createdRequests.append(request)
        return try createResult.get()
    }

    func getOrder(id: String) async throws -> Order { try getOrderResult.get() }
    func getOrders(status: OrderStatus?, limit: Int, offset: Int) async throws -> OrdersListResponse {
        OrdersListResponse(success: true, orders: [try getOrderResult.get()], totalCount: 1, hasMore: false)
    }
    func getActiveOrders() async throws -> [Order] { [try getOrderResult.get()].filter(\.status.isActive) }
    func cancelOrder(id: String, reason: String?) async throws -> Order {
        cancelledOrderIds.append(id)
        var order = try getOrderResult.get()
        order.status = .cancelled
        return order
    }
    func undoCancelOrder(id: String) async throws -> Order { try getOrderResult.get() }
    func reportOrderIssue(id: String, category: String, subject: String, description: String?) async throws {
        reportedIssues.append((id, category, subject, description))
    }
}

final class MockDeliveryRepository: DeliveryRepositoryProtocol, @unchecked Sendable {
    var availability: DeliveryAvailability

    @MainActor
    convenience init() {
        self.init(availability: TestFactory.deliveryAvailability())
    }

    init(availability: DeliveryAvailability) {
        self.availability = availability
    }

    func getAddresses() async throws -> [DeliveryAddress] { [] }
    func saveAddress(_ address: DeliveryAddress) async throws -> DeliveryAddress { address }
    func updateAddress(_ address: DeliveryAddress) async throws -> DeliveryAddress { address }
    func deleteAddress(id: String) async throws {}
    func setDefaultAddress(id: String) async throws {}
    func checkAvailability(addressId: String?, latitude: Double?, longitude: Double?, storeId: String) async throws -> DeliveryAvailability { availability }
    func getDeliveryZones(storeId: String) async throws -> [DeliveryZone] { [] }
    func getDeliveryTracking(orderId: String) async throws -> DeliveryTracking { throw TestError.requestedFailure }
}

final class MockVoucherRepository: VoucherRepositoryProtocol, @unchecked Sendable {
    var validation = VoucherValidation(valid: true, voucher: nil, discountAmount: 10_000, message: nil)
    func getVouchers() async throws -> [Voucher] { [] }
    func getCachedVouchers() async -> [Voucher]? { [] }
    func refreshVouchers() async throws -> [Voucher] { [] }
    func validateVoucher(code: String, subtotal: Double, mode: OrderingMode) async throws -> VoucherValidation { validation }
    func fetchAndDistributeVouchers(userId: String) async throws -> [Voucher] { [] }
}

final class MockPredictionRepository: PredictionRepositoryProtocol, @unchecked Sendable {
    private(set) var recordedOrders: [[CartItem]] = []
    func getHistory() async -> [PredictionHistoryItem] { [] }
    func saveHistory(_ items: [PredictionHistoryItem]) async {}
    func recordOrder(items: [CartItem], context: PredictionContext) async { recordedOrders.append(items) }
    func recordOrderFromHistory(order: Order) async {}
    func getDismissals() async -> [Date] { [] }
    func recordDismissal() async {}
    func clearDismissals() async {}
    func getSuppressedCombos() async -> Set<String> { [] }
    func suppressCombo(_ key: String) async {}
    func getLastSyncDate() async -> Date? { nil }
    func setLastSyncDate(_ date: Date) async {}
}

final class MockAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    private(set) var events: [(String, [String: Any]?)] = []
    private(set) var purchases: [(String, Double, [OrderItem])] = []
    func trackEvent(_ name: String, properties: [String: Any]?) async { events.append((name, properties)) }
    func trackScreen(_ name: String) async {}
    func setUserProperty(_ name: String, value: String?) async {}
    func trackPurchase(orderId: String, amount: Double, items: [OrderItem]) async { purchases.append((orderId, amount, items)) }
}

final class MockHapticService: HapticServiceProtocol, @unchecked Sendable {
    private(set) var notifications: [HapticNotificationType] = []
    func impact(_ style: HapticStyle) async {}
    func notification(_ type: HapticNotificationType) async { notifications.append(type) }
    func selection() async {}
}

final class InMemoryOrderStorage: OrderStorageProtocol {
    private var draft: OrderDraft?
    private(set) var didClearDraft = false
    func saveDraft(_ draft: OrderDraft) { self.draft = draft }
    func loadDraft() -> OrderDraft? { draft }
    func clearDraft() { didClearDraft = true; draft = nil }
}

@MainActor
enum TestFactory {
    static func product(
        id: String = "prod-espresso",
        name: String = "Espresso Blend",
        categoryId: String = "coffee",
        basePrice: Double = 68_000,
        isActive: Bool = true,
        isStoreAvailable: Bool? = true,
        isDeliverable: Bool = true
    ) -> Product {
        Product(
            id: id,
            name: name,
            description: "Test coffee",
            categoryId: categoryId,
            categoryName: "Coffee",
            imageUrl: nil,
            basePrice: basePrice,
            sizeOptions: [
                SizeOption(size: .small, price: basePrice - 8_000, isEnabled: true),
                SizeOption(size: .medium, price: basePrice, isEnabled: true),
                SizeOption(size: .large, price: basePrice + 10_000, isEnabled: true)
            ],
            availableToppings: ["white-pearl", "black-pearl"],
            isPopular: true,
            isNew: false,
            isActive: isActive,
            isStoreAvailable: isStoreAvailable,
            inventoryState: isStoreAvailable == false ? .soldOut : .available,
            quantityOnHand: nil,
            hasStoreOverride: isStoreAvailable != nil,
            usesQuantityInventory: false,
            isHotSupported: true,
            isDeliverable: isDeliverable,
            deliveryPrepMinutes: 8,
            tags: ["coffee"],
            nutritionInfo: nil,
            allergens: []
        )
    }

    static func topping(id: String = "white-pearl", name: String = "Tran Chau Trang", price: Double = 10_000, quantity: Int = 1) -> ToppingSelection {
        ToppingSelection(id: id, name: name, price: price, quantity: quantity)
    }

    static func customization(toppings: [ToppingSelection] = []) -> OrderCustomization {
        OrderCustomization(size: .medium, sugar: .full, ice: .normal, toppings: toppings)
    }

    static func cartItem(quantity: Int = 1, storeId: String = "store-d1") -> CartItem {
        cartItem(product: product(), quantity: quantity, storeId: storeId, customization: customization())
    }

    static func cartItem(product: Product, quantity: Int = 1, storeId: String = "store-d1") -> CartItem {
        cartItem(product: product, quantity: quantity, storeId: storeId, customization: customization())
    }

    static func cartItem(product: Product, quantity: Int = 1, storeId: String = "store-d1", customization: OrderCustomization) -> CartItem {
        let price = product.price(for: customization.size) + customization.toppingsTotal
        return CartItem(
            key: CartItem.generateKey(product: product, modifiers: customization, priceSnapshot: price, storeId: storeId),
            product: product,
            quantity: quantity,
            customization: customization,
            addedAt: Date(timeIntervalSince1970: 1_700_000_000),
            priceSnapshot: price,
            storeId: storeId
        )
    }

    static func cart(items: [CartItem]? = nil, storeId: String? = "store-d1", mode: OrderingMode = .pickup) -> Cart {
        Cart(items: items ?? [cartItem(storeId: storeId ?? "")], mode: mode, storeId: storeId)
    }

    static func order(id: String = "order-1", status: OrderStatus = .placed, paymentUrl: String? = nil) -> Order {
        let item = OrderItem(
            id: "item-1",
            orderId: id,
            productId: "prod-espresso",
            productName: "Espresso Blend",
            productImage: nil,
            quantity: 1,
            unitPrice: 68_000,
            finalPrice: 68_000,
            customization: customization()
        )
        return Order(
            id: id,
            userId: "user-1",
            storeId: "store-d1",
            status: status,
            mode: .pickup,
            paymentMethod: .card,
            items: [item],
            subtotal: 68_000,
            deliveryFee: 0,
            discount: 0,
            totalAmount: 73_440,
            tableId: nil,
            deliveryAddress: nil,
            deliveryNotes: nil,
            staffNotes: nil,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            estimatedReadyAt: nil,
            completedAt: nil,
            cancelledAt: nil,
            cancellationReason: nil,
            paymentUrl: paymentUrl,
            tax: 5_440,
            taxRate: 0.08,
            pointsUsed: 0,
            voucherSnapshot: nil,
            storeSnapshot: StoreSnapshot(id: "store-d1", name: "District 1", address: "123 Nguyen Hue", phone: nil)
        )
    }

    static func deliveryAvailability(available: Bool = true) -> DeliveryAvailability {
        DeliveryAvailability(
            available: available,
            storeId: "store-d1",
            zone: nil,
            fee: DeliveryFee(amount: 15_000, baseFee: 10_000, distanceFee: 5_000, surgeFee: nil, isSurge: false, surgeMultiplier: nil),
            eta: nil,
            minOrderAmount: 50_000,
            unavailableReason: available ? nil : .temporarilyUnavailable,
            unavailableProducts: nil
        )
    }
}
