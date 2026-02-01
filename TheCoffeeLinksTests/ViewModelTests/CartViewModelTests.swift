//
//  CartViewModelTests.swift
//  TheCoffeeLinksTests
//
//  Tests for cart functionality with comprehensive coverage
//

import XCTest
import Combine
@testable import TheCoffeeLinks

@MainActor
final class CartViewModelTests: TestBaseClass {
    
    // MARK: - Properties
    
    var cartViewModel: CartViewModel!
    var mockCartService: MockCartService!
    var mockDeliveryService: MockDeliveryService!
    var mockHapticService: MockHapticService!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        setupMocks()
        createCartViewModel()
    }
    
    override func tearDown() {
        super.tearDown()
        cartViewModel = nil
        clearMocks()
    }
    
    private func setupMocks() {
        mockCartService = MockCartService()
        mockDeliveryService = MockDeliveryService()
        mockHapticService = MockHapticService()
    }
    
    private func clearMocks() {
        mockCartService = nil
        mockDeliveryService = nil
        mockHapticService = nil
    }
    
    private func createCartViewModel() {
        cartViewModel = CartViewModel(
            deliveryRepository: MockDeliveryRepository(),
            voucherRepository: MockVoucherRepository(),
            hapticService: mockHapticService,
            cartService: mockCartService
        )
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(cartViewModel.items.isEmpty)
        XCTAssertEqual(cartViewModel.subtotal, 0)
        XCTAssertEqual(cartViewModel.total, 0)
        XCTAssertFalse(cartViewModel.isLoading)
        XCTAssertNil(cartViewModel.appliedVoucher)
        XCTAssertNil(cartViewModel.selectedDeliveryAddress)
    }
    
    // MARK: - Add Items Tests
    
    func testAddItemToCart() {
        // Given
        let product = TestDataFactory.createProduct()
        let quantity = 2
        
        // When
        cartViewModel.addItem(product: product, quantity: quantity)
        
        // Then
        XCTAssertEqual(cartViewModel.items.count, 1)
        XCTAssertEqual(cartViewModel.items.first?.quantity, quantity)
        XCTAssertEqual(cartViewModel.items.first?.product.id, product.id)
        
        // Verify haptic feedback
        XCTAssertTrue(mockHapticService.feedbackTriggered)
    }
    
    func testAddMultipleDifferentItems() {
        // Given
        let products = TestDataFactory.createProducts()
        
        // When
        for product in products {
            cartViewModel.addItem(product: product, quantity: 1)
        }
        
        // Then
        XCTAssertEqual(cartViewModel.items.count, products.count)
        XCTAssertEqual(Set(cartViewModel.items.map { $0.product.id }), Set(products.map { $0.id }))
    }
    
    func testAddSameItemMultipleTimes() {
        // Given
        let product = TestDataFactory.createProduct()
        
        // When
        cartViewModel.addItem(product: product, quantity: 1)
        cartViewModel.addItem(product: product, quantity: 2)
        
        // Then
        XCTAssertEqual(cartViewModel.items.count, 1) // Should merge, not create separate items
        XCTAssertEqual(cartViewModel.items.first?.quantity, 3)
    }
    
    func testAddItemWithCustomizations() {
        // Given
        let product = TestDataFactory.createProduct()
        let sizeOption = TestDataFactory.createSizeOptions().first!
        let toppings = TestDataFactory.createToppings()
        
        // When
        cartViewModel.addItem(
            product: product,
            quantity: 1,
            sizeOption: sizeOption,
            toppings: toppings
        )
        
        // Then
        let item = cartViewModel.items.first!
        XCTAssertEqual(item.selectedSize?.id, sizeOption.id)
        XCTAssertEqual(item.selectedToppings.count, toppings.count)
    }
    
    // MARK: - Remove Items Tests
    
    func testRemoveItemFromCart() {
        // Given
        let product = TestDataFactory.createProduct()
        cartViewModel.addItem(product: product, quantity: 2)
        let itemId = cartViewModel.items.first!.id
        
        // When
        cartViewModel.removeItem(itemId: itemId)
        
        // Then
        XCTAssertTrue(cartViewModel.items.isEmpty)
    }
    
    func testRemoveNonExistentItem() {
        // Given
        let product = TestDataFactory.createProduct()
        cartViewModel.addItem(product: product, quantity: 1)
        let originalCount = cartViewModel.items.count
        
        // When
        cartViewModel.removeItem(itemId: "non_existent_id")
        
        // Then
        XCTAssertEqual(cartViewModel.items.count, originalCount)
    }
    
    // MARK: - Update Quantity Tests
    
    func testUpdateItemQuantity() {
        // Given
        let product = TestDataFactory.createProduct()
        cartViewModel.addItem(product: product, quantity: 1)
        let itemId = cartViewModel.items.first!.id
        
        // When
        cartViewModel.updateQuantity(itemId: itemId, quantity: 5)
        
        // Then
        XCTAssertEqual(cartViewModel.items.first?.quantity, 5)
    }
    
    func testUpdateQuantityToZero() {
        // Given
        let product = TestDataFactory.createProduct()
        cartViewModel.addItem(product: product, quantity: 3)
        let itemId = cartViewModel.items.first!.id
        
        // When
        cartViewModel.updateQuantity(itemId: itemId, quantity: 0)
        
        // Then
        XCTAssertTrue(cartViewModel.items.isEmpty)
    }
    
    func testUpdateQuantityOfNonExistentItem() {
        // Given
        let product = TestDataFactory.createProduct()
        cartViewModel.addItem(product: product, quantity: 1)
        let originalQuantity = cartViewModel.items.first!.quantity
        
        // When
        cartViewModel.updateQuantity(itemId: "non_existent_id", quantity: 10)
        
        // Then
        XCTAssertEqual(cartViewModel.items.first?.quantity, originalQuantity)
    }
    
    // MARK: - Total Calculation Tests
    
    func testSubtotalCalculation() {
        // Given
        let products = TestDataFactory.createProducts()
        
        // When
        for product in products {
            cartViewModel.addItem(product: product, quantity: 2)
        }
        
        // Then
        let expectedSubtotal = products.reduce(0) { $0 + ($1.basePrice * 2) }
        XCTAssertEqual(cartViewModel.subtotal, expectedSubtotal)
    }
    
    func testTotalCalculationWithDeliveryFee() {
        // Given
        let product = TestDataFactory.createProduct(basePrice: 50000)
        cartViewModel.addItem(product: product, quantity: 1)
        
        mockDeliveryService.deliveryFee = 25000
        cartViewModel.deliveryService = mockDeliveryService
        
        // When
        let total = cartViewModel.total
        
        // Then
        XCTAssertEqual(total, 50000 + 25000)
    }
    
    func testTotalCalculationWithVoucher() {
        // Given
        let product = TestDataFactory.createProduct(basePrice: 100000)
        cartViewModel.addItem(product: product, quantity: 1)
        
        let voucher = TestDataFactory.createVoucher(discountAmount: 20000)
        cartViewModel.appliedVoucher = voucher
        
        // When
        let total = cartViewModel.total
        
        // Then
        XCTAssertEqual(total, 100000 - 20000)
    }
    
    func testTotalCalculationWithVoucherAndDelivery() {
        // Given
        let product = TestDataFactory.createProduct(basePrice: 100000)
        cartViewModel.addItem(product: product, quantity: 1)
        
        let voucher = TestDataFactory.createVoucher(discountAmount: 15000)
        cartViewModel.appliedVoucher = voucher
        
        mockDeliveryService.deliveryFee = 30000
        cartViewModel.deliveryService = mockDeliveryService
        
        // When
        let total = cartViewModel.total
        
        // Then
        XCTAssertEqual(total, 100000 - 15000 + 30000) // 115,000
    }
    
    // MARK: - Voucher Tests
    
    func testApplyValidVoucher() async {
        // Given
        let product = TestDataFactory.createProduct(basePrice: 100000)
        cartViewModel.addItem(product: product, quantity: 1)
        
        let voucher = TestDataFactory.createVoucher(
            minimumOrderAmount: 50000,
            discountAmount: 20000
        )
        
        // When
        let result = await cartViewModel.applyVoucher(voucher)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(cartViewModel.appliedVoucher?.id, voucher.id)
        XCTAssertEqual(cartViewModel.discountAmount, 20000)
    }
    
    func testApplyVoucherWithInsufficientOrderAmount() async {
        // Given
        let product = TestDataFactory.createProduct(basePrice: 30000)
        cartViewModel.addItem(product: product, quantity: 1)
        
        let voucher = TestDataFactory.createVoucher(
            minimumOrderAmount: 50000,
            discountAmount: 20000
        )
        
        // When
        let result = await cartViewModel.applyVoucher(voucher)
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNil(cartViewModel.appliedVoucher)
        XCTAssertEqual(cartViewModel.discountAmount, 0)
    }
    
    func testRemoveVoucher() async {
        // Given
        let product = TestDataFactory.createProduct(basePrice: 100000)
        cartViewModel.addItem(product: product, quantity: 1)
        
        let voucher = TestDataFactory.createVoucher(discountAmount: 20000)
        _ = await cartViewModel.applyVoucher(voucher)
        
        // When
        cartViewModel.removeVoucher()
        
        // Then
        XCTAssertNil(cartViewModel.appliedVoucher)
        XCTAssertEqual(cartViewModel.discountAmount, 0)
    }
    
    // MARK: - Clear Cart Tests
    
    func testClearCart() {
        // Given
        let products = TestDataFactory.createProducts()
        for product in products {
            cartViewModel.addItem(product: product, quantity: 1)
        }
        
        XCTAssertFalse(cartViewModel.items.isEmpty)
        
        // When
        cartViewModel.clearCart()
        
        // Then
        XCTAssertTrue(cartViewModel.items.isEmpty)
        XCTAssertEqual(cartViewModel.subtotal, 0)
        XCTAssertEqual(cartViewModel.total, 0)
        XCTAssertNil(cartViewModel.appliedVoucher)
    }
    
    // MARK: - Delivery Address Tests
    
    func testSelectDeliveryAddress() async {
        // Given
        let address = TestDataFactory.createDeliveryAddress()
        
        // When
        await cartViewModel.selectDeliveryAddress(address)
        
        // Then
        XCTAssertEqual(cartViewModel.selectedDeliveryAddress?.id, address.id)
        XCTAssertGreaterThan(cartViewModel.deliveryFee, 0) // Should calculate delivery fee
    }
    
    func testRemoveDeliveryAddress() {
        // Given
        let address = TestDataFactory.createDeliveryAddress()
        cartViewModel.selectedDeliveryAddress = address
        cartViewModel.deliveryFee = 25000
        
        // When
        cartViewModel.removeDeliveryAddress()
        
        // Then
        XCTAssertNil(cartViewModel.selectedDeliveryAddress)
        XCTAssertEqual(cartViewModel.deliveryFee, 0)
    }
    
    // MARK: - Validation Tests
    
    func testCanProceedToCheckout() {
        // Given - empty cart
        XCTAssertFalse(cartViewModel.canProceedToCheckout)
        
        // When - add items
        let product = TestDataFactory.createProduct()
        cartViewModel.addItem(product: product, quantity: 1)
        
        // Then
        XCTAssertTrue(cartViewModel.canProceedToCheckout)
    }
    
    func testCannotCheckoutWithNonDeliverableItems() {
        // Given
        let nonDeliverableProduct = TestDataFactory.createProduct(isDeliverable: false)
        cartViewModel.addItem(product: nonDeliverableProduct, quantity: 1)
        cartViewModel.isDeliveryMode = true
        
        // When/Then
        XCTAssertFalse(cartViewModel.canProceedToCheckoutForDelivery)
    }
    
    func testCanCheckoutWithDeliverableItems() {
        // Given
        let deliverableProduct = TestDataFactory.createProduct(isDeliverable: true)
        cartViewModel.addItem(product: deliverableProduct, quantity: 1)
        cartViewModel.isDeliveryMode = true
        
        // When/Then
        XCTAssertTrue(cartViewModel.canProceedToCheckoutForDelivery)
    }
    
    // MARK: - Edge Cases Tests
    
    func testMaxQuantityLimiting() {
        // Given
        let product = TestDataFactory.createProduct()
        cartViewModel.addItem(product: product, quantity: 1)
        let itemId = cartViewModel.items.first!.id
        
        // When - try to update to very high quantity
        cartViewModel.updateQuantity(itemId: itemId, quantity: 1000)
        
        // Then - should be limited to reasonable maximum
        let maxAllowed = cartViewModel.maxQuantityPerItem
        XCTAssertLessThanOrEqual(cartViewModel.items.first!.quantity, maxAllowed)
    }
    
    func testHandleInactiveProducts() {
        // Given
        let inactiveProduct = TestDataFactory.createProduct(isActive: false)
        
        // When
        let canAdd = cartViewModel.canAddProduct(inactiveProduct)
        
        // Then
        XCTAssertFalse(canAdd)
    }
    
    // MARK: - Performance Tests
    
    func testLargeCartPerformance() {
        measure {
            // Add many items to cart
            for i in 0..<100 {
                let product = TestDataFactory.createProduct(id: "product_\(i)")
                cartViewModel.addItem(product: product, quantity: 1)
            }
            
            // Calculate totals
            _ = cartViewModel.subtotal
            _ = cartViewModel.total
        }
    }
}

// MARK: - Additional Mock Services

class MockHapticService {
    var feedbackTriggered = false
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        feedbackTriggered = true
    }
}

class MockDeliveryRepository {
    var shouldFail = false
    
    func calculateDeliveryFee(for address: DeliveryAddress) async throws -> Double {
        if shouldFail {
            throw NetworkError.networkFailure(URLError(.notConnectedToInternet))
        }
        return 25000
    }
    
    func validateAddress(_ address: DeliveryAddress) async throws -> Bool {
        if shouldFail {
            throw NetworkError.networkFailure(URLError(.notConnectedToInternet))
        }
        return true
    }
}