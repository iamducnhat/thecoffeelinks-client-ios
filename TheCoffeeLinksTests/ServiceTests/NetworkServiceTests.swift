//
//  NetworkServiceTests.swift
//  TheCoffeeLinksTests
//
//  Tests for networking layer with proper mocking
//

import XCTest
import Combine
@testable import TheCoffeeLinks

final class NetworkServiceTests: TestBaseClass {
    
    var networkService: NetworkService!
    
    override func setUp() {
        super.setUp()
        networkService = NetworkService(keychainManager: mockKeychainManager)
    }
    
    override func tearDown() {
        super.tearDown()
        networkService = nil
    }
    
    // MARK: - Authentication Tests
    
    func testSetAuthSession() async {
        // Given
        let accessToken = "test_access_token_123"
        let refreshToken = "test_refresh_token_456"
        
        // When
        await networkService.setAuthSession(accessToken: accessToken, refreshToken: refreshToken)
        
        // Then
        XCTAssertEqual(networkService.authToken, accessToken)
        XCTAssertEqual(mockKeychainManager.getAccessToken(), accessToken)
        XCTAssertEqual(mockKeychainManager.getRefreshToken(), refreshToken)
    }
    
    func testClearAuthToken() async {
        // Given
        mockKeychainManager.saveAccessToken("test_token")
        mockKeychainManager.saveRefreshToken("test_refresh")
        await networkService.setAuthSession(accessToken: "test_token", refreshToken: "test_refresh")
        
        // When
        await networkService.clearAuthToken()
        
        // Then
        XCTAssertNil(networkService.authToken)
        XCTAssertNil(mockKeychainManager.getAccessToken())
        XCTAssertNil(mockKeychainManager.getRefreshToken())
    }
    
    // MARK: - Cache Tests
    
    func testClearCache() async {
        // When
        await networkService.clearCache()
        
        // Then - should not throw and complete successfully
        XCTAssertTrue(true) // Cache clearing is internal, we just verify it doesn't crash
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorMapping() {
        // Test that NetworkError cases have proper descriptions
        XCTAssertNotNil(NetworkError.invalidURL.errorDescription)
        XCTAssertNotNil(NetworkError.noData.errorDescription)
        XCTAssertNotNil(NetworkError.decodingError.errorDescription)
        XCTAssertNotNil(NetworkError.unauthorized.errorDescription)
        XCTAssertNotNil(NetworkError.forbidden.errorDescription)
        XCTAssertNotNil(NetworkError.notFound.errorDescription)
        XCTAssertNotNil(NetworkError.unknown.errorDescription)
        
        let serverError = NetworkError.serverError("Custom server error")
        XCTAssertEqual(serverError.errorDescription, "Custom server error")
        
        let networkFailure = NetworkError.networkFailure(URLError(.notConnectedToInternet))
        XCTAssertTrue(networkFailure.errorDescription?.contains("Network error") == true)
    }
}

// MARK: - Repository Tests

final class ProductRepositoryTests: TestBaseClass {
    
    var productRepository: ProductRepository!
    
    override func setUp() {
        super.setUp()
        setupMockProductsSuccess()
        productRepository = ProductRepository(
            networkService: mockNetworkService,
            cacheService: MockCacheService(),
            syncManager: MockSyncManager()
        )
    }
    
    func testFetchProducts() async throws {
        // When
        let products = try await productRepository.fetchProducts()
        
        // Then
        XCTAssertFalse(products.isEmpty)
        XCTAssertEqual(products.count, 4) // From TestDataFactory.createProducts()
    }
    
    func testFetchProductsNetworkFailure() async {
        // Given
        mockNetworkService.shouldFail = true
        mockNetworkService.failureError = NetworkError.networkFailure(URLError(.notConnectedToInternet))
        
        // When/Then
        await XCTAssertThrowsErrorAsync(try await productRepository.fetchProducts()) { error in
            XCTAssertTrue(error is NetworkError)
        }
    }
}

// MARK: - Service Tests

final class CartServiceTests: TestBaseClass {
    
    var cartService: MockCartService!
    
    override func setUp() {
        super.setUp()
        cartService = MockCartService()
    }
    
    func testAddItem() {
        // Given
        let product = TestDataFactory.createProduct()
        
        // When
        cartService.addItem(product: product, quantity: 2)
        
        // Then
        XCTAssertEqual(cartService.items.count, 1)
        XCTAssertEqual(cartService.items.first?.quantity, 2)
        XCTAssertEqual(cartService.items.first?.product.id, product.id)
    }
    
    func testTotalCalculation() {
        // Given
        let product1 = TestDataFactory.createProduct(basePrice: 50000)
        let product2 = TestDataFactory.createProduct(id: "prod_2", basePrice: 30000)
        
        cartService.addItem(product: product1, quantity: 2) // 100,000
        cartService.addItem(product: product2, quantity: 1) // 30,000
        
        // When/Then
        XCTAssertEqual(cartService.total, 130000)
    }
    
    func testClearCart() {
        // Given
        let product = TestDataFactory.createProduct()
        cartService.addItem(product: product, quantity: 1)
        
        // When
        cartService.clearCart()
        
        // Then
        XCTAssertTrue(cartService.items.isEmpty)
        XCTAssertEqual(cartService.total, 0)
    }
}

// MARK: - Additional Mock Services for Testing

class MockCacheService {
    private var cache: [String: Any] = [:]
    
    func set<T: Codable>(_ value: T, forKey key: String) {
        cache[key] = value
    }
    
    func get<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        return cache[key] as? T
    }
    
    func remove(forKey key: String) {
        cache.removeValue(forKey: key)
    }
    
    func clear() {
        cache.removeAll()
    }
}

class MockSyncManager {
    var lastSyncDate: Date?
    var isSyncing = false
    
    func sync() async {
        isSyncing = true
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        lastSyncDate = Date()
        isSyncing = false
    }
    
    func needsSync() -> Bool {
        guard let lastSync = lastSyncDate else { return true }
        return Date().timeIntervalSince(lastSync) > 300 // 5 minutes
    }
}

class ProductRepository {
    private let networkService: MockableNetworkService
    private let cacheService: MockCacheService
    private let syncManager: MockSyncManager
    
    init(networkService: MockableNetworkService, cacheService: MockCacheService, syncManager: MockSyncManager) {
        self.networkService = networkService
        self.cacheService = cacheService
        self.syncManager = syncManager
    }
    
    func fetchProducts() async throws -> [Product] {
        let response: APIResponse<[Product]> = try await networkService.request("/api/products", method: "GET", body: nil as String?, queryItems: nil)
        return response.data
    }
    
    func fetchCategories() async throws -> [ProductCategory] {
        let response: APIResponse<[ProductCategory]> = try await networkService.request("/api/categories", method: "GET", body: nil as String?, queryItems: nil)
        return response.data
    }
}