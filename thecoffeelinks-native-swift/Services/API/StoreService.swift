import Foundation

class StoreService: StoreServiceProtocol {
    private let apiClient = APIClient.shared
    
    func getStores() async throws -> [Store] {
        let response: StoreResponse = try await apiClient.get("/api/stores")
        return response.stores ?? response.data ?? []
    }
}

struct StoreResponse: Decodable {
    let stores: [Store]?
    let data: [Store]?
    let error: String?
}

protocol StoreServiceProtocol {
    func getStores() async throws -> [Store]
}
