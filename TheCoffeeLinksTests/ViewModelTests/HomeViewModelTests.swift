//
//  ProductViewModelTests.swift
//  TheCoffeeLinksTests
//
//  Tests for product-related ViewModels
//

import XCTest
import Combine
@testable import TheCoffeeLinks

@MainActor
final class HomeViewModelTests: TestBaseClass {
    
    // MARK: - Properties
    
    var homeViewModel: HomeViewModel!
    var mockProductRepository: MockProductRepository!
    var mockVoucherRepository: MockVoucherRepository!
    var mockFavoritesRepository: MockFavoritesRepository!
    var mockAnalyticsService: MockAnalyticsService!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        setupMocks()
        createHomeViewModel()
    }
    
    override func tearDown() {
        super.tearDown()
        homeViewModel = nil
        clearMocks()
    }
    
    private func setupMocks() {
        mockProductRepository = MockProductRepository()
        mockVoucherRepository = MockVoucherRepository()
        mockFavoritesRepository = MockFavoritesRepository()
        mockAnalyticsService = MockAnalyticsService()
    }
    
    private func clearMocks() {
        mockProductRepository = nil
        mockVoucherRepository = nil
        mockFavoritesRepository = nil
        mockAnalyticsService = nil
    }
    
    private func createHomeViewModel() {
        // In a real implementation, this would use dependency injection
        // For now, we'll create a simplified version
        homeViewModel = HomeViewModel(
            productRepository: mockProductRepository,
            voucherRepository: mockVoucherRepository,
            favoritesRepository: mockFavoritesRepository,
            predictionRepository: MockPredictionRepository(),
            userRepository: MockUserRepository(),
            analyticsService: mockAnalyticsService,
            networkService: mockNetworkService,
            predictionSyncService: MockPredictionSyncService(),
            refreshCoordinator: MockRefreshCoordinator()
        )
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(homeViewModel.products.isEmpty)
        XCTAssertTrue(homeViewModel.categories.isEmpty)
        XCTAssertTrue(homeViewModel.popularProducts.isEmpty)
        XCTAssertFalse(homeViewModel.isLoading)
        XCTAssertNil(homeViewModel.selectedCategory)
    }
    
    // MARK: - Product Loading Tests
    
    func testSuccessfulProductLoading() async {
        // Given
        let expectedProducts = TestDataFactory.createProducts()
        mockProductRepository.mockProducts = expectedProducts
        
        // When
        await homeViewModel.loadProducts()
        
        // Then
        XCTAssertEqual(homeViewModel.products.count, expectedProducts.count)
        XCTAssertFalse(homeViewModel.isLoading)
        XCTAssertNil(homeViewModel.error)
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalyticsService.trackedEvents.contains { $0.event == "products_loaded" })
    }
    
    func testProductLoadingFailure() async {
        // Given
        mockProductRepository.shouldFail = true
        
        // When
        await homeViewModel.loadProducts()
        
        // Then
        XCTAssertTrue(homeViewModel.products.isEmpty)
        XCTAssertFalse(homeViewModel.isLoading)
        XCTAssertNotNil(homeViewModel.error)
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalyticsService.trackedEvents.contains { $0.event == "products_load_failed" })
    }
    
    func testProductLoadingLoadingState() async {
        // Given
        let products = TestDataFactory.createProducts()
        mockProductRepository.mockProducts = products
        
        // When
        let loadingTask = Task {
            await homeViewModel.loadProducts()
        }
        
        // Then - should be loading initially
        XCTAssertTrue(homeViewModel.isLoading)
        
        // Wait for completion
        await loadingTask.value
        
        // Should not be loading after completion
        XCTAssertFalse(homeViewModel.isLoading)
    }
    
    // MARK: - Category Loading Tests
    
    func testSuccessfulCategoryLoading() async {
        // Given
        let expectedCategories = TestDataFactory.createCategories()
        mockProductRepository.mockCategories = expectedCategories
        
        // When
        await homeViewModel.loadCategories()
        
        // Then
        XCTAssertEqual(homeViewModel.categories.count, expectedCategories.count)
        XCTAssertFalse(homeViewModel.isLoading)
    }
    
    func testCategoryLoadingFailure() async {
        // Given
        mockProductRepository.shouldFail = true
        
        // When
        await homeViewModel.loadCategories()
        
        // Then
        XCTAssertTrue(homeViewModel.categories.isEmpty)
        XCTAssertNotNil(homeViewModel.error)
    }
    
    // MARK: - Product Filtering Tests
    
    func testFilterProductsByCategory() async {
        // Given
        let products = TestDataFactory.createProducts()
        let categories = TestDataFactory.createCategories()
        mockProductRepository.mockProducts = products
        mockProductRepository.mockCategories = categories
        
        await homeViewModel.loadProducts()
        await homeViewModel.loadCategories()
        
        // When
        homeViewModel.selectCategory(categories.first!)
        
        // Then
        XCTAssertEqual(homeViewModel.selectedCategory?.id, categories.first!.id)
        // Filtered products should only show products from selected category
        let filteredProducts = homeViewModel.filteredProducts
        XCTAssertTrue(filteredProducts.allSatisfy { $0.categoryId == categories.first!.id })
    }
    
    func testClearCategoryFilter() async {
        // Given
        let products = TestDataFactory.createProducts()
        let categories = TestDataFactory.createCategories()
        mockProductRepository.mockProducts = products
        mockProductRepository.mockCategories = categories
        
        await homeViewModel.loadProducts()
        await homeViewModel.loadCategories()
        
        homeViewModel.selectCategory(categories.first!)
        
        // When
        homeViewModel.clearCategoryFilter()
        
        // Then
        XCTAssertNil(homeViewModel.selectedCategory)
        XCTAssertEqual(homeViewModel.filteredProducts.count, products.count)
    }
    
    // MARK: - Search Tests
    
    func testProductSearch() async {
        // Given
        let products = TestDataFactory.createProducts()
        mockProductRepository.mockProducts = products
        
        await homeViewModel.loadProducts()
        
        // When
        await homeViewModel.searchProducts(query: "Cappuccino")
        
        // Then
        let searchResults = homeViewModel.searchResults
        XCTAssertTrue(searchResults.allSatisfy { $0.name.lowercased().contains("cappuccino") })
        
        // Verify analytics
        XCTAssertTrue(mockAnalyticsService.trackedEvents.contains { 
            $0.event == "product_search" && $0.parameters["query"] as? String == "Cappuccino"
        })
    }
    
    func testEmptySearch() async {
        // Given
        let products = TestDataFactory.createProducts()
        mockProductRepository.mockProducts = products
        
        await homeViewModel.loadProducts()
        
        // When
        await homeViewModel.searchProducts(query: "")
        
        // Then
        XCTAssertTrue(homeViewModel.searchResults.isEmpty)
    }
    
    func testSearchWithNoResults() async {
        // Given
        let products = TestDataFactory.createProducts()
        mockProductRepository.mockProducts = products
        
        await homeViewModel.loadProducts()
        
        // When
        await homeViewModel.searchProducts(query: "NonexistentProduct")
        
        // Then
        XCTAssertTrue(homeViewModel.searchResults.isEmpty)
    }
    
    // MARK: - Popular Products Tests
    
    func testPopularProductsFiltering() async {
        // Given
        var products = TestDataFactory.createProducts()
        products[0].isPopular = true
        products[1].isPopular = true
        products[2].isPopular = false
        products[3].isPopular = false
        
        mockProductRepository.mockProducts = products
        
        // When
        await homeViewModel.loadProducts()
        
        // Then
        XCTAssertEqual(homeViewModel.popularProducts.count, 2)
        XCTAssertTrue(homeViewModel.popularProducts.allSatisfy { $0.isPopular })
    }
    
    // MARK: - Refresh Tests
    
    func testRefreshData() async {
        // Given
        let initialProducts = TestDataFactory.createProducts()
        mockProductRepository.mockProducts = initialProducts
        
        await homeViewModel.loadProducts()
        XCTAssertEqual(homeViewModel.products.count, initialProducts.count)
        
        // Change mock data
        let updatedProducts = TestDataFactory.createProducts() + [TestDataFactory.createProduct(id: "new_product")]
        mockProductRepository.mockProducts = updatedProducts
        
        // When
        await homeViewModel.refreshData()
        
        // Then
        XCTAssertEqual(homeViewModel.products.count, updatedProducts.count)
        XCTAssertTrue(homeViewModel.products.contains { $0.id == "new_product" })
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorRecovery() async {
        // Given - initial failure
        mockProductRepository.shouldFail = true
        await homeViewModel.loadProducts()
        
        XCTAssertNotNil(homeViewModel.error)
        XCTAssertTrue(homeViewModel.products.isEmpty)
        
        // When - retry with success
        mockProductRepository.shouldFail = false
        mockProductRepository.mockProducts = TestDataFactory.createProducts()
        
        await homeViewModel.retryLastOperation()
        
        // Then
        XCTAssertNil(homeViewModel.error)
        XCTAssertFalse(homeViewModel.products.isEmpty)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryCleanupOnDeinit() {
        weak var weakViewModel: HomeViewModel?
        
        autoreleasepool {
            let viewModel = HomeViewModel(
                productRepository: mockProductRepository,
                voucherRepository: mockVoucherRepository,
                favoritesRepository: mockFavoritesRepository,
                predictionRepository: MockPredictionRepository(),
                userRepository: MockUserRepository(),
                analyticsService: mockAnalyticsService,
                networkService: mockNetworkService,
                predictionSyncService: MockPredictionSyncService(),
                refreshCoordinator: MockRefreshCoordinator()
            )
            weakViewModel = viewModel
        }
        
        // Wait for deallocation
        XCTAssertEventuallyTrue({ weakViewModel == nil }, timeout: 2.0, message: "HomeViewModel should be deallocated")
    }
}

// MARK: - Additional Mock Services

class MockVoucherRepository {
    var shouldFail = false
    var mockVouchers: [Voucher] = []
    
    func fetchAvailableVouchers() async throws -> [Voucher] {
        if shouldFail {
            throw NetworkError.networkFailure(URLError(.notConnectedToInternet))
        }
        return mockVouchers
    }
}

class MockFavoritesRepository {
    var shouldFail = false
    var mockFavorites: Set<String> = []
    
    func getFavoriteProductIds() async throws -> Set<String> {
        if shouldFail {
            throw NetworkError.networkFailure(URLError(.notConnectedToInternet))
        }
        return mockFavorites
    }
    
    func addToFavorites(productId: String) async throws {
        if shouldFail {
            throw NetworkError.networkFailure(URLError(.notConnectedToInternet))
        }
        mockFavorites.insert(productId)
    }
    
    func removeFromFavorites(productId: String) async throws {
        if shouldFail {
            throw NetworkError.networkFailure(URLError(.notConnectedToInternet))
        }
        mockFavorites.remove(productId)
    }
}

class MockPredictionRepository {
    func getPredictedProducts(for userId: String) async throws -> [Product] {
        return TestDataFactory.createProducts().prefix(2).map { $0 }
    }
}

class MockUserRepository {
    var shouldFail = false
    
    func getCurrentUser() async throws -> User {
        if shouldFail {
            throw NetworkError.unauthorized
        }
        return TestDataFactory.createUser()
    }
}

class MockPredictionSyncService {
    func syncPredictions() async {
        // Mock implementation
    }
}

class MockRefreshCoordinator {
    func scheduleRefresh() {
        // Mock implementation
    }
}