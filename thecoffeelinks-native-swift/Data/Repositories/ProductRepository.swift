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
    
    func getMenu() async throws -> Menu {
        if let cached: Menu = await cacheService.get(menuCacheKey) { return cached }
        
        do {
            let response: APIMenuResponse = try await networkService.get("/api/menu", queryItems: nil)
            let menu = response.toMenu()
            await cacheService.set(menuCacheKey, value: menu, ttl: menuCacheTTL)
            return menu
        } catch {
            print("❌ Menu fetch error: \(error)")
            if let data = (error as NSError).userInfo["responseData"] as? Data,
               let json = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(json.prefix(500))")
            }
            throw error
        }
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
    
    func getPopularProducts(period: String, limit: Int) async throws -> [PopularProduct] {
        let queryItems = [URLQueryItem(name: "period", value: period), URLQueryItem(name: "limit", value: String(limit))]
        let response: PopularProductsResponse = try await networkService.get("/api/products/popular", queryItems: queryItems)
        return response.products
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
