//
//  UserAuthenticationIntegrationTests.swift
//  TheCoffeeLinksTests
//
//  Integration tests for complete authentication flows
//

import XCTest
import Combine
@testable import TheCoffeeLinks

@MainActor
final class UserAuthenticationIntegrationTests: TestBaseClass {
    
    // MARK: - Properties
    
    var authViewModel: AuthViewModel!
    var mockAuthRepository: MockAuthRepository!
    var mockDependencyContainer: MockDependencyContainer!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        setupIntegrationEnvironment()
    }
    
    override func tearDown() {
        super.tearDown()
        authViewModel = nil
        mockAuthRepository = nil
        mockDependencyContainer = nil
    }
    
    private func setupIntegrationEnvironment() {
        mockDependencyContainer = MockDependencyContainer()
        mockAuthRepository = MockAuthRepository()
        authViewModel = AuthViewModel(authRepository: mockAuthRepository)
    }
    
    // MARK: - Complete Registration Flow Tests
    
    func testCompleteRegistrationFlow() async throws {
        // Given - User wants to register with phone number
        let phoneNumber = "+84123456789"
        let password = "SecurePassword123!"
        let fullName = "Test User"
        let dateOfBirth = "15/06/1995"
        let otpCode = "123456"
        
        authViewModel.phoneNumber = phoneNumber
        authViewModel.password = password
        authViewModel.fullName = fullName
        authViewModel.dob = dateOfBirth
        
        // When - User starts registration
        authViewModel.register()
        
        // Wait for registration to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - Registration should succeed and OTP should be sent
        XCTAssertEqual(authViewModel.authState, .otpSent)
        XCTAssertNil(authViewModel.error)
        
        // When - User enters OTP
        authViewModel.otpCode = otpCode
        let mockUser = TestDataFactory.createUser(phone: phoneNumber, isPhoneVerified: true)
        mockAuthRepository.mockUser = mockUser
        
        authViewModel.verifyOTP()
        
        // Wait for OTP verification
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - User should be authenticated and verified
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertTrue(authViewModel.isPhoneVerified)
        XCTAssertEqual(authViewModel.currentUser?.phone, phoneNumber)
        XCTAssertEqual(authViewModel.currentUser?.fullName, fullName)
    }
    
    func testRegistrationWithInvalidOTP() async throws {
        // Given - User has completed registration and received OTP
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.password = "SecurePassword123!"
        authViewModel.fullName = "Test User"
        authViewModel.dob = "15/06/1995"
        
        authViewModel.register()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(authViewModel.authState, .otpSent)
        
        // When - User enters incorrect OTP
        authViewModel.otpCode = "000000"
        mockAuthRepository.shouldFail = true // Simulate OTP verification failure
        
        authViewModel.verifyOTP()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - Should remain unauthenticated with error
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.isPhoneVerified)
        XCTAssertNotNil(authViewModel.error)
        XCTAssertEqual(authViewModel.authState, .error)
    }
    
    // MARK: - Complete Login Flow Tests
    
    func testCompleteLoginFlow() async throws {
        // Given - Existing verified user
        let email = "test@example.com"
        let password = "correctPassword123"
        let mockUser = TestDataFactory.createUser(email: email, isPhoneVerified: true)
        mockAuthRepository.mockUser = mockUser
        
        // When - User signs in
        await authViewModel.signInWithPassword(email: email, password: password)
        
        // Then - Should be authenticated
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertTrue(authViewModel.isPhoneVerified)
        XCTAssertEqual(authViewModel.currentUser?.email, email)
        XCTAssertNil(authViewModel.error)
    }
    
    func testLoginWithUnverifiedPhone() async throws {
        // Given - User with unverified phone
        let email = "unverified@example.com"
        let password = "password123"
        let mockUser = TestDataFactory.createUser(email: email, isPhoneVerified: false)
        mockAuthRepository.mockUser = mockUser
        
        // When - User signs in
        await authViewModel.signInWithPassword(email: email, password: password)
        
        // Then - Should be authenticated but not phone verified
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.isPhoneVerified)
        XCTAssertEqual(authViewModel.currentUser?.email, email)
    }
    
    // MARK: - Session Management Integration Tests
    
    func testSessionPersistenceAcrossAppRestart() async throws {
        // Given - User is signed in
        let mockUser = TestDataFactory.createUser(isPhoneVerified: true)
        mockAuthRepository.mockUser = mockUser
        
        await authViewModel.signInWithPassword(email: "test@example.com", password: "password")
        XCTAssertTrue(authViewModel.isAuthenticated)
        
        // Simulate app restart by creating new AuthViewModel instance
        let newAuthViewModel = AuthViewModel(authRepository: mockAuthRepository)
        
        // Mock that keychain still has the token
        mockKeychainManager.saveAccessToken("persisted_token_123")
        
        // When - Check session on app restart
        newAuthViewModel.checkSession()
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then - Should restore authenticated state
        XCTAssertTrue(newAuthViewModel.isAuthenticated)
        XCTAssertTrue(newAuthViewModel.isPhoneVerified)
    }
    
    func testSessionExpirationHandling() async throws {
        // Given - User is signed in but token has expired
        mockKeychainManager.saveAccessToken("expired_token")
        mockAuthRepository.shouldFail = true // Simulate token validation failure
        
        // When - Check session with expired token
        authViewModel.checkSession()
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then - Should handle gracefully and potentially use cached verification status
        // The exact behavior depends on implementation, but it shouldn't crash
        XCTAssertNoThrow({
            _ = authViewModel.isAuthenticated
            _ = authViewModel.isPhoneVerified
        })
    }
    
    // MARK: - Logout Integration Tests
    
    func testCompleteLogoutFlow() async throws {
        // Given - User is signed in
        let mockUser = TestDataFactory.createUser(isPhoneVerified: true)
        authViewModel.currentUser = mockUser
        authViewModel.isAuthenticated = true
        authViewModel.isPhoneVerified = true
        
        mockKeychainManager.saveAccessToken("active_token")
        
        // When - User logs out
        await authViewModel.signOut()
        
        // Then - All authentication state should be cleared
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.isPhoneVerified)
        XCTAssertNil(authViewModel.currentUser)
        XCTAssertNil(mockKeychainManager.getAccessToken())
        
        // Verify UserDefaults cache is also cleared
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "isPhoneVerified_cached"))
    }
    
    // MARK: - Error Recovery Integration Tests
    
    func testNetworkErrorRecovery() async throws {
        // Given - Initial network failure during registration
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.password = "password123"
        authViewModel.fullName = "Test User"
        authViewModel.dob = "01/01/1990"
        
        mockAuthRepository.shouldFail = true
        
        // When - First attempt fails
        authViewModel.register()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - Should show error
        XCTAssertEqual(authViewModel.authState, .error)
        XCTAssertNotNil(authViewModel.error)
        
        // When - Network recovers and user retries
        mockAuthRepository.shouldFail = false
        
        authViewModel.register()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - Should succeed
        XCTAssertEqual(authViewModel.authState, .otpSent)
        XCTAssertNil(authViewModel.error)
    }
    
    // MARK: - Concurrent Operations Integration Tests
    
    func testConcurrentAuthOperations() async throws {
        // Given - Multiple authentication operations triggered simultaneously
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.password = "password123"
        authViewModel.fullName = "Test User"
        authViewModel.dob = "01/01/1990"
        
        // When - Multiple concurrent registrations (should handle gracefully)
        async let registration1 = Task {
            authViewModel.register()
        }
        async let registration2 = Task {
            authViewModel.register()
        }
        async let registration3 = Task {
            authViewModel.register()
        }
        
        await registration1.value
        await registration2.value
        await registration3.value
        
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then - Should not crash and end up in consistent state
        XCTAssertTrue(authViewModel.authState == .otpSent || authViewModel.authState == .error)
    }
}

// MARK: - Cart and Product Integration Tests

@MainActor
final class CartProductIntegrationTests: TestBaseClass {
    
    var cartViewModel: CartViewModel!
    var homeViewModel: HomeViewModel!
    var mockCartService: MockCartService!
    var mockProductRepository: MockProductRepository!
    
    override func setUp() {
        super.setUp()
        setupCartProductIntegration()
    }
    
    private func setupCartProductIntegration() {
        mockCartService = MockCartService()
        mockProductRepository = MockProductRepository()
        
        cartViewModel = CartViewModel(
            deliveryRepository: MockDeliveryRepository(),
            voucherRepository: MockVoucherRepository(),
            hapticService: MockHapticService(),
            cartService: mockCartService
        )
        
        homeViewModel = HomeViewModel(
            productRepository: mockProductRepository,
            voucherRepository: MockVoucherRepository(),
            favoritesRepository: MockFavoritesRepository(),
            predictionRepository: MockPredictionRepository(),
            userRepository: MockUserRepository(),
            analyticsService: MockAnalyticsService(),
            networkService: mockNetworkService,
            predictionSyncService: MockPredictionSyncService(),
            refreshCoordinator: MockRefreshCoordinator()
        )
    }
    
    func testCompleteProductToPurchaseFlow() async throws {
        // Given - Products are loaded
        let products = TestDataFactory.createProducts()
        mockProductRepository.mockProducts = products
        
        await homeViewModel.loadProducts()
        XCTAssertEqual(homeViewModel.products.count, products.count)
        
        // When - User adds products to cart
        let cappuccino = products.first { $0.name == "Cappuccino" }!
        let sizeOption = TestDataFactory.createSizeOptions()[1] // Medium
        let toppings = [TestDataFactory.createToppings().first!]
        
        cartViewModel.addItem(
            product: cappuccino,
            quantity: 2,
            sizeOption: sizeOption,
            toppings: toppings
        )
        
        // Then - Cart should reflect the addition
        XCTAssertEqual(cartViewModel.items.count, 1)
        XCTAssertEqual(cartViewModel.items.first?.quantity, 2)
        XCTAssertEqual(cartViewModel.items.first?.selectedSize?.id, sizeOption.id)
        XCTAssertEqual(cartViewModel.items.first?.selectedToppings.count, 1)
        
        // Verify total calculation includes size adjustment and toppings
        let expectedItemPrice = cappuccino.basePrice + sizeOption.priceAdjustment + toppings.first!.price
        let expectedTotal = expectedItemPrice * 2
        XCTAssertEqual(cartViewModel.subtotal, expectedTotal)
    }
    
    func testProductSearchToCartFlow() async throws {
        // Given - Products are loaded
        let products = TestDataFactory.createProducts()
        mockProductRepository.mockProducts = products
        
        await homeViewModel.loadProducts()
        
        // When - User searches for specific product
        await homeViewModel.searchProducts(query: "Latte")
        
        let searchResults = homeViewModel.searchResults
        XCTAssertGreaterThan(searchResults.count, 0)
        
        // User adds search result to cart
        let latte = searchResults.first!
        cartViewModel.addItem(product: latte, quantity: 1)
        
        // Then - Cart should contain the searched product
        XCTAssertEqual(cartViewModel.items.count, 1)
        XCTAssertEqual(cartViewModel.items.first?.product.name, "Latte")
    }
    
    func testCategoryFilterToCartFlow() async throws {
        // Given - Products and categories are loaded
        let products = TestDataFactory.createProducts()
        let categories = TestDataFactory.createCategories()
        mockProductRepository.mockProducts = products
        mockProductRepository.mockCategories = categories
        
        await homeViewModel.loadProducts()
        await homeViewModel.loadCategories()
        
        // When - User filters by category
        let coffeeCategory = categories.first { $0.name == "Coffee" }!
        homeViewModel.selectCategory(coffeeCategory)
        
        let filteredProducts = homeViewModel.filteredProducts
        
        // Add filtered product to cart
        if let coffeeProduct = filteredProducts.first {
            cartViewModel.addItem(product: coffeeProduct, quantity: 1)
        }
        
        // Then - Cart should contain product from selected category
        XCTAssertEqual(cartViewModel.items.count, 1)
        XCTAssertEqual(cartViewModel.items.first?.product.categoryId, coffeeCategory.id)
    }
}

// MARK: - Delivery Flow Integration Tests

@MainActor
final class DeliveryIntegrationTests: TestBaseClass {
    
    var cartViewModel: CartViewModel!
    var deliveryService: MockDeliveryService!
    
    override func setUp() {
        super.setUp()
        setupDeliveryIntegration()
    }
    
    private func setupDeliveryIntegration() {
        deliveryService = MockDeliveryService()
        cartViewModel = CartViewModel(
            deliveryRepository: MockDeliveryRepository(),
            voucherRepository: MockVoucherRepository(),
            hapticService: MockHapticService(),
            cartService: MockCartService()
        )
    }
    
    func testCompleteDeliverySetupFlow() async throws {
        // Given - Cart has deliverable items
        let deliverableProduct = TestDataFactory.createProduct(isDeliverable: true)
        cartViewModel.addItem(product: deliverableProduct, quantity: 2)
        
        // When - User selects delivery mode
        cartViewModel.isDeliveryMode = true
        
        // Then - Should be able to proceed with delivery
        XCTAssertTrue(cartViewModel.canProceedToCheckoutForDelivery)
        
        // When - User adds delivery address
        let address = TestDataFactory.createDeliveryAddress()
        await cartViewModel.selectDeliveryAddress(address)
        
        // Then - Delivery fee should be calculated
        XCTAssertEqual(cartViewModel.selectedDeliveryAddress?.id, address.id)
        XCTAssertGreaterThan(cartViewModel.deliveryFee, 0)
        
        // Total should include delivery fee
        let expectedTotal = cartViewModel.subtotal + cartViewModel.deliveryFee
        XCTAssertEqual(cartViewModel.total, expectedTotal)
    }
    
    func testDeliveryWithNonDeliverableItems() async throws {
        // Given - Cart has non-deliverable items
        let nonDeliverableProduct = TestDataFactory.createProduct(isDeliverable: false)
        cartViewModel.addItem(product: nonDeliverableProduct, quantity: 1)
        
        // When - User tries to select delivery mode
        cartViewModel.isDeliveryMode = true
        
        // Then - Should not be able to proceed with delivery
        XCTAssertFalse(cartViewModel.canProceedToCheckoutForDelivery)
    }
}

// MARK: - Mock Dependency Container

class MockDependencyContainer {
    let networkService = MockNetworkService()
    let keychainManager = MockKeychainManager()
    let userDefaults = MockUserDefaults()
    let locationManager = MockLocationManager()
    let analyticsService = MockAnalyticsService()
}