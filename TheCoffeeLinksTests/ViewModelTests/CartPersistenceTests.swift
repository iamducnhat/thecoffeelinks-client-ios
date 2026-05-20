import XCTest
@testable import TheCoffeeLinks

@MainActor
final class CartPersistenceTests: XCTestCase {
    func testViewModelRemoveThenAddDoesNotResurrectDeletedQuantity() async {
        let product = TestFactory.product()
        let customization = TestFactory.customization()
        let item = TestFactory.cartItem(product: product, quantity: 19, storeId: "store-d1", customization: customization)
        let service = InMemoryCartService(cart: TestFactory.cart(items: [item], storeId: "store-d1"))
        let viewModel = CartViewModel(
            deliveryRepository: MockDeliveryRepository(),
            voucherRepository: MockVoucherRepository(),
            hapticService: MockHapticService(),
            cartService: service
        )

        XCTAssertEqual(viewModel.itemCount, 19)

        viewModel.removeItem(item.id)
        await waitUntil { viewModel.itemCount == 0 && service.loadLocalCart()?.itemCount == 0 }

        viewModel.addItem(product: product, quantity: 1, customization: customization)
        await waitUntil { viewModel.itemCount == 1 && service.loadLocalCart()?.itemCount == 1 }

        XCTAssertEqual(viewModel.itemCount, 1)
        XCTAssertEqual(service.loadLocalCart()?.itemCount, 1)
    }

    func testViewModelUpdateQuantityToZeroPersistsRemoval() async {
        let item = TestFactory.cartItem(quantity: 1)
        let service = InMemoryCartService(cart: TestFactory.cart(items: [item], storeId: "store-d1"))
        let viewModel = CartViewModel(
            deliveryRepository: MockDeliveryRepository(),
            voucherRepository: MockVoucherRepository(),
            hapticService: MockHapticService(),
            cartService: service
        )

        viewModel.updateQuantity(for: item.id, delta: -1)
        await waitUntil { viewModel.itemCount == 0 && service.loadLocalCart()?.itemCount == 0 }

        XCTAssertTrue(service.loadLocalCart()?.items.isEmpty == true)
    }

    func testCartOperationRemoveThenAddDoesNotResurrectQuantity() {
        let product = TestFactory.product()
        let customization = TestFactory.customization()
        let item = TestFactory.cartItem(product: product, quantity: 19, storeId: "store-d1", customization: customization)
        let newItem = CartItem(
            key: item.key,
            product: product,
            quantity: 1,
            customization: customization,
            addedAt: Date(),
            priceSnapshot: item.priceSnapshot,
            storeId: item.storeId
        )
        var cart = TestFactory.cart(items: [item], storeId: "store-d1")

        cart.applyOperation(.remove(key: item.id))
        cart.addItem(newItem)

        XCTAssertEqual(cart.itemCount, 1)
        XCTAssertEqual(cart.uniqueItemCount, 1)
    }

    private func waitUntil(
        timeout: TimeInterval = 1,
        condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertTrue(condition(), file: file, line: line)
    }
}

private final class InMemoryCartService: CartServiceProtocol {
    private var cart: Cart

    init(cart: Cart) {
        self.cart = cart
    }

    func loadLocalCart() -> Cart? { cart }
    func fetchRemoteCart() async throws -> Cart { cart }

    func addToCart(productId: UUID, quantity: Int, modifiers: OrderCustomization) async throws -> Cart {
        cart
    }

    func addToCart(product: Product, quantity: Int, modifiers: OrderCustomization) async throws -> Cart {
        let priceSnapshot = product.price(for: modifiers.size) + modifiers.toppingsTotal
        let storeId = cart.storeId ?? ""
        let item = CartItem(
            key: CartItem.generateKey(product: product, modifiers: modifiers, priceSnapshot: priceSnapshot, storeId: storeId),
            product: product,
            quantity: quantity,
            customization: modifiers,
            addedAt: Date(),
            priceSnapshot: priceSnapshot,
            storeId: storeId
        )
        cart.addItem(item)
        cart.lastUpdated = Date()
        cart.isDirty = true
        return cart
    }

    func updateQuantity(key: String, delta: Int) async throws -> Cart {
        cart.updateQuantity(for: key, delta: delta)
        cart.lastUpdated = Date()
        cart.isDirty = true
        return cart
    }

    func removeItem(key: String) async throws -> Cart {
        cart.removeItem(key)
        cart.lastUpdated = Date()
        cart.isDirty = true
        return cart
    }

    func replaceItem(oldKey: String, item: CartItem) async throws -> Cart {
        cart.removeItem(oldKey)
        cart.addItem(item)
        cart.lastUpdated = Date()
        cart.isDirty = true
        return cart
    }

    func clearCart() async throws {
        cart.clear()
        cart.lastUpdated = Date()
        cart.isDirty = true
    }

    func getOperationQueueSize() -> Int { 0 }
}
