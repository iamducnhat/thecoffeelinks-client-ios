//
//  PerformanceTests.swift
//  TheCoffeeLinksTests
//
//  Performance and memory tests for critical app components
//

import XCTest
import Combine
@testable import TheCoffeeLinks

final class PerformanceTests: TestBaseClass {
    
    // MARK: - Model Performance Tests
    
    func testProductDecodingPerformance() throws {
        // Given - Large JSON response
        let products = (0..<1000).map { i in
            TestDataFactory.createProduct(id: "prod_\(i)", name: "Product \(i)")
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(products)
        
        let decoder = JSONDecoder()
        
        // When/Then - Measure decoding performance
        measure {
            do {
                _ = try decoder.decode([Product].self, from: data)
            } catch {
                XCTFail("Decoding failed: \(error)")
            }
        }
    }
    
    func testCartCalculationPerformance() {
        let cartService = MockCartService()
        
        // Given - Large number of cart items
        let products = (0..<100).map { i in
            TestDataFactory.createProduct(id: "prod_\(i)", basePrice: Double(10000 + i * 1000))
        }
        
        for product in products {
            cartService.addItem(product: product, quantity: Int.random(in: 1...5))
        }
        
        // When/Then - Measure total calculation performance
        measure {
            _ = cartService.total
        }
    }
    
    // MARK: - ViewModel Performance Tests
    
    func testHomeViewModelProductProcessingPerformance() async {
        let mockProductRepository = MockProductRepository()
        let homeViewModel = HomeViewModel(
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
        
        // Given - Large product dataset
        let products = (0..<1000).map { i in
            TestDataFactory.createProduct(id: "prod_\(i)", name: "Product \(i)")
        }
        mockProductRepository.mockProducts = products
        
        // When/Then - Measure product loading performance
        await measureAsync {
            await homeViewModel.loadProducts()
        }
    }
    
    func testSearchPerformance() async {
        let mockProductRepository = MockProductRepository()
        let homeViewModel = HomeViewModel(
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
        
        // Given - Large product dataset
        let products = (0..<10000).map { i in
            TestDataFactory.createProduct(
                id: "prod_\(i)", 
                name: i % 3 == 0 ? "Coffee Product \(i)" : "Food Product \(i)"
            )
        }
        mockProductRepository.mockProducts = products
        
        await homeViewModel.loadProducts()
        
        // When/Then - Measure search performance
        await measureAsync {
            await homeViewModel.searchProducts(query: "Coffee")
        }
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageDuringLargeDataLoading() async {
        let mockProductRepository = MockProductRepository()
        
        // Create large dataset
        let products = (0..<5000).map { i in
            TestDataFactory.createProduct(id: "prod_\(i)", name: "Product \(i)")
        }
        mockProductRepository.mockProducts = products
        
        // Measure memory during multiple ViewModel creations
        measure(metrics: [XCTMemoryMetric()]) {
            autoreleasepool {
                let homeViewModel = HomeViewModel(
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
                
                let expectation = XCTestExpectation(description: "Products loaded")
                Task {
                    await homeViewModel.loadProducts()
                    expectation.fulfill()
                }
                wait(for: [expectation], timeout: 5.0)
            }
        }
    }
    
    func testMemoryLeaksInViewModels() {
        weak var weakAuthViewModel: AuthViewModel?
        weak var weakHomeViewModel: HomeViewModel?
        weak var weakCartViewModel: CartViewModel?
        
        // Create ViewModels in autorelease pool
        autoreleasepool {
            let authViewModel = AuthViewModel(authRepository: MockAuthRepository())
            let homeViewModel = HomeViewModel(
                productRepository: MockProductRepository(),
                voucherRepository: MockVoucherRepository(),
                favoritesRepository: MockFavoritesRepository(),
                predictionRepository: MockPredictionRepository(),
                userRepository: MockUserRepository(),
                analyticsService: MockAnalyticsService(),
                networkService: mockNetworkService,
                predictionSyncService: MockPredictionSyncService(),
                refreshCoordinator: MockRefreshCoordinator()
            )
            let cartViewModel = CartViewModel(
                deliveryRepository: MockDeliveryRepository(),
                voucherRepository: MockVoucherRepository(),
                hapticService: MockHapticService(),
                cartService: MockCartService()
            )
            
            weakAuthViewModel = authViewModel
            weakHomeViewModel = homeViewModel
            weakCartViewModel = cartViewModel
        }
        
        // Force garbage collection
        autoreleasepool { }
        
        // ViewModels should be deallocated
        XCTAssertNil(weakAuthViewModel, "AuthViewModel should be deallocated")
        XCTAssertNil(weakHomeViewModel, "HomeViewModel should be deallocated")
        XCTAssertNil(weakCartViewModel, "CartViewModel should be deallocated")
    }
    
    // MARK: - Concurrent Performance Tests
    
    func testConcurrentCartOperations() {
        let cartService = MockCartService()
        let products = TestDataFactory.createProducts()
        
        measure {
            let expectations = (0..<100).map { i in
                XCTestExpectation(description: "Operation \(i)")
            }
            
            // Perform concurrent cart operations
            DispatchQueue.concurrentPerform(iterations: 100) { i in
                let product = products[i % products.count]
                cartService.addItem(product: product, quantity: 1)
                expectations[i].fulfill()
            }
            
            wait(for: expectations, timeout: 5.0)
        }
    }
    
    func testConcurrentNetworkRequests() {
        let networkService = MockNetworkService()
        setupMockProductsSuccess()
        
        measure {
            let expectations = (0..<50).map { i in
                XCTestExpectation(description: "Request \(i)")
            }
            
            // Simulate concurrent API calls
            for i in 0..<50 {
                Task {
                    do {
                        let _: APIResponse<[Product]> = try await networkService.request("/api/products", method: "GET", body: nil as String?, queryItems: nil)
                        expectations[i].fulfill()
                    } catch {
                        expectations[i].fulfill()
                    }
                }
            }
            
            wait(for: expectations, timeout: 10.0)
        }
    }
    
    // MARK: - UI Performance Tests
    
    func testCollectionViewScrollingPerformance() {
        // This would typically test UICollectionView performance
        // In a real implementation, you'd measure actual scrolling metrics
        measure(metrics: [XCTCPUMetric()]) {
            // Simulate heavy collection view operations
            let products = (0..<1000).map { i in
                TestDataFactory.createProduct(id: "prod_\(i)")
            }
            
            // Simulate cell configuration
            for product in products {
                _ = product.name
                _ = product.basePrice
                _ = product.imageUrl
            }
        }
    }
    
    // MARK: - Database Performance Tests (if using Core Data)
    
    func testDataPersistencePerformance() {
        // Mock data persistence operations
        measure {
            let products = (0..<100).map { i in
                TestDataFactory.createProduct(id: "prod_\(i)")
            }
            
            // Simulate saving to persistence layer
            let encoder = JSONEncoder()
            for product in products {
                do {
                    _ = try encoder.encode(product)
                } catch {
                    XCTFail("Encoding failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Image Loading Performance
    
    func testImageCachePerformance() {
        let imageCache = ImageCache()
        let imageUrls = (0..<100).map { "https://example.com/image_\($0).jpg" }
        
        measure {
            for url in imageUrls {
                // Simulate image cache operations
                imageCache.setImage(UIImage(), forKey: url)
                _ = imageCache.image(forKey: url)
            }
        }
    }
}

// MARK: - Mock Image Cache

class ImageCache {
    private var cache: [String: UIImage] = [:]
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache[key] = image
    }
    
    func image(forKey key: String) -> UIImage? {
        return cache[key]
    }
    
    func removeImage(forKey key: String) {
        cache.removeValue(forKey: key)
    }
    
    func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Performance Benchmarks

extension PerformanceTests {
    
    func testBaselinePerformanceBenchmarks() {
        // Establish baseline performance metrics
        
        // JSON Parsing Benchmark
        let jsonData = TestDataFactory.validProductJSON.data(using: .utf8)!
        measure(metrics: [XCTCPUMetric(limitingToCurrentThread: true)]) {
            do {
                _ = try JSONDecoder().decode(Product.self, from: jsonData)
            } catch {
                XCTFail("Baseline JSON parsing failed")
            }
        }
    }
    
    func testWorstCaseScenarios() {
        // Test performance under worst-case conditions
        
        // Large cart with many customizations
        let cartService = MockCartService()
        
        measure {
            for i in 0..<100 {
                let product = TestDataFactory.createProduct(id: "prod_\(i)")
                let sizeOptions = TestDataFactory.createSizeOptions()
                let toppings = TestDataFactory.createToppings()
                
                cartService.addItem(
                    product: product,
                    quantity: 10,
                    sizeOption: sizeOptions.last, // Most expensive
                    toppings: toppings // All toppings
                )
            }
            
            // Calculate totals for large cart
            _ = cartService.total
        }
    }
}