import Foundation

// MARK: - API Response Wrappers

struct ProductsResponse: Decodable {
    let products: [Product]?
    let data: [Product]?
    let error: String?
    
    var items: [Product] {
        products ?? data ?? []
    }
}

struct SingleProductResponse: Decodable {
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
        ], keyDecodingStrategy: .useDefaultKeys)
        return response.items
    }
    
    func getProduct(id: String) async throws -> Product {
        let response: SingleProductResponse = try await apiClient.get("/api/products/\(id)", keyDecodingStrategy: .useDefaultKeys)
        guard let product = response.product else {
            throw APIClient.APIError.notFound
        }
        return product
    }
    
    func getCategories() async throws -> [Category] {
        let response: CategoriesResponse = try await apiClient.get("/api/categories")
        return response.categories ?? []
    }
}
