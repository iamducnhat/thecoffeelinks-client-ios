//
//  ProductRepository.swift
//  thecoffeelinks-client-ios
//

import Foundation

final class ProductRepository: ProductRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let syncManager: SyncManager
    private let menuCacheTTL: TimeInterval = 300
    
    init(networkService: NetworkServiceProtocol, cacheService: CacheServiceProtocol, syncManager: SyncManager) {
        self.networkService = networkService
        self.cacheService = cacheService
        self.syncManager = syncManager
    }

    private func normalizedStoreId(_ storeId: String?) -> String? {
        let trimmed = storeId?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private func menuCacheKey(for storeId: String?) -> String {
        if let storeId = normalizedStoreId(storeId) {
            return "menu_cache_\(storeId)"
        }
        return "menu_cache_global"
    }

    private func menuVersionKey(for storeId: String?) -> String {
        if let storeId = normalizedStoreId(storeId) {
            return "menu:\(storeId)"
        }
        return "menu:global"
    }
    
    func getCachedMenu(storeId: String?) async -> Menu? {
        guard let data: Data = await cacheService.get(menuCacheKey(for: storeId)) else { return nil }
        return try? JSONDecoder().decode(Menu.self, from: data)
    }
    
    func refreshMenu(storeId: String?) async throws -> Menu {
        let queryItems = normalizedStoreId(storeId).map { [URLQueryItem(name: "store_id", value: $0)] }
        let response: APIMenuResponse = try await networkService.get("/api/menu", queryItems: queryItems)
        let menu = response.toMenu()
        
        if let data = try? JSONEncoder().encode(menu) {
            await cacheService.set(menuCacheKey(for: storeId), value: data, ttl: menuCacheTTL)
        }
        
        // Update local version if we have a server version from sync manager
        if let serverVersion = syncManager.serverVersion(for: "menu") {
            syncManager.updateLocalVersion(key: menuVersionKey(for: storeId), version: serverVersion)
        }
        
        return menu
    }
    
    func getMenu(storeId: String?) async throws -> Menu {
        // 1. Try to get from cache
        if let data: Data = await cacheService.get(menuCacheKey(for: storeId)),
           let cached = try? JSONDecoder().decode(Menu.self, from: data) {
            // If cache was persisted during a temporary empty-data incident, force refresh.
            if cached.products.isEmpty {
                return try await refreshMenu(storeId: storeId)
            }
            
            // 2. Check if stale
            if let serverVersion = syncManager.serverVersion(for: "menu") {
                if syncManager.isStale(key: menuVersionKey(for: storeId), serverVersion: serverVersion) {
                    return try await refreshMenu(storeId: storeId)
                }
            }
            return cached
        }
        
        // 3. Not in cache or version unknown (first time), fetch and update
        return try await refreshMenu(storeId: storeId)
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
