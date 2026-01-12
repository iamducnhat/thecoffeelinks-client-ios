import Foundation

// MARK: - API Response Wrappers

struct ProductsResponse: Codable {
    let products: [Product]?
    let data: [Product]?
    let error: String?
    
    var items: [Product] {
        products ?? data ?? []
    }
}

struct SingleProductResponse: Codable {
    let product: Product?
    let error: String?
}

// MARK: - ProductService

class ProductService: ProductServiceProtocol {
    private let apiClient = APIClient.shared
    
    func getProducts() async throws -> [Product] {
        let response: ProductsResponse = try await apiClient.get("/api/products")
        return response.items
    }
    
    func getFeaturedProducts() async throws -> [Product] {
        let response: ProductsResponse = try await apiClient.get("/api/products", queryItems: [
            URLQueryItem(name: "featured", value: "true")
        ])
        return response.items
    }
    
    func getProduct(id: String) async throws -> Product {
        let response: SingleProductResponse = try await apiClient.get("/api/products/\(id)")
        guard let product = response.product else {
            throw APIError.notFound
        }
        return product
    }
}
