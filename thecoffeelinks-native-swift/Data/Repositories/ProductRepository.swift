//
//  ProductRepository.swift
//  thecoffeelinks-native-swift
//

import Foundation

final class ProductRepository: ProductRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let menuCacheKey = "menu_cache"
    private let menuCacheTTL: TimeInterval = 300
    
    init(networkService: NetworkServiceProtocol, cacheService: CacheServiceProtocol) {
        self.networkService = networkService
        self.cacheService = cacheService
    }
    
    func getCachedMenu() async -> Menu? {
        guard let data: Data = await cacheService.get(menuCacheKey) else { return nil }
        return try? JSONDecoder().decode(Menu.self, from: data)
    }
    
    func refreshMenu() async throws -> Menu {
        let response: APIMenuResponse = try await networkService.get("/api/menu", queryItems: nil)
        let menu = response.toMenu()
        
        if let data = try? JSONEncoder().encode(menu) {
            await cacheService.set(menuCacheKey, value: data, ttl: menuCacheTTL)
        }
        
        return menu
    }
    
    func getMenu() async throws -> Menu {
        // Fallback for legacy calls: Try cache first, then refresh
        // Use locally decoded data if available
        if let data: Data = await cacheService.get(menuCacheKey),
           let cached = try? JSONDecoder().decode(Menu.self, from: data) {
            return cached
        }
        return try await refreshMenu()
    }
    
    func getProducts(categoryId: String?) async throws -> [Product] {
        var queryItems: [URLQueryItem]?
        if let categoryId = categoryId { queryItems = [URLQueryItem(name: "categoryId", value: categoryId)] }
        let response: ProductsResponse = try await networkService.get("/api/products", queryItems: queryItems)
        return response.products
    }
    
    func getProduct(id: String) async throws -> Product {
        let response: ProductsResponse = try await networkService.get("/api/products/\(id)", queryItems: nil)
        guard let product = response.products.first else { throw ProductError.notFound }
        return product
    }
    
    func getCategories() async throws -> [Category] {
        let response: CategoriesResponse = try await networkService.get("/api/categories", queryItems: nil)
        return response.categories
    }
    
    func getToppings() async throws -> [Topping] {
        let response: ToppingsResponse = try await networkService.get("/api/toppings", queryItems: nil)
        return response.toppings
    }
    
    // MARK: - Popular Products
    
    private func getPopularCacheKey(period: String) -> String { "popular_\(period)" }
    
    func getCachedPopularProducts() async -> [PopularProduct]? {
        // Retrieve as Data to assume Sendable safety, then decode locally
        guard let data: Data = await cacheService.get(getPopularCacheKey(period: "daily")) else { return nil }
        return try? JSONDecoder().decode([PopularProduct].self, from: data)
    }
    
    func refreshPopularProducts(period: String, limit: Int) async throws -> [PopularProduct] {
        let queryItems = [URLQueryItem(name: "period", value: period), URLQueryItem(name: "limit", value: String(limit))]
        
        // 1. Fetch raw API response with IDs
        let response: APIPopularProductsResponse = try await networkService.get("/api/products/popular", queryItems: queryItems)
        
        // 2. Ensure we have the full menu
        let menu = try await getMenu()
        
        // 3. Map responses
        let populars = response.products.enumerated().compactMap { index, item -> PopularProduct? in
            guard let fullProduct = menu.products.first(where: { $0.id == item.id }) else { return nil }
            return PopularProduct(
                id: UUID().uuidString,
                product: fullProduct,
                orderCount: item.orderCount ?? 0,
                rank: index + 1,
                trend: .stable
            )
        }
        
        // Convert to Data before passing to Actor to avoid "Main actor-isolated conformance" issues
        if let data = try? JSONEncoder().encode(populars) {
            await cacheService.set(getPopularCacheKey(period: period), value: data, ttl: menuCacheTTL)
        }
        
        return populars
    }
    
    func getPopularProducts(period: String, limit: Int) async throws -> [PopularProduct] {
        // Check cache (expecting Data)
        if let data: Data = await cacheService.get(getPopularCacheKey(period: period)),
           let cached = try? JSONDecoder().decode([PopularProduct].self, from: data) {
            return cached
        }
        return try await refreshPopularProducts(period: period, limit: limit)
    }
    
    func searchProducts(query: String) async throws -> [Product] {
        let response: ProductsResponse = try await networkService.get("/api/products/search", queryItems: [URLQueryItem(name: "q", value: query)])
        return response.products
    }
}

enum ProductError: LocalizedError {
    case notFound
    var errorDescription: String? { "Product not found" }
}
