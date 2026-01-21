import Foundation
import CoreLocation

// Note: StoreRepository should be in Data layer, but currently located in Core/Repositories
class StoreRepository {
    private let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func getStores() async throws -> [Store] {
        let response: StoresResponse = try await networkService.request("/api/stores")
        return response.stores
    }
    
    func getStore(id: String) async throws -> Store {
        let response: StoreResponse = try await networkService.request("/api/stores/\(id)")
        return response.store
    }
    
    func getNearestStore(latitude: Double, longitude: Double) async throws -> Store? {
        // Find nearest store logic could be server-side or client-side filtering
        // For efficiency, let's ask the server if supported, otherwise filter client side
        let allStores: [Store] = try await getStores()
        
        let clientLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        return allStores.min(by: { store1, store2 in
            // Direct access since Store model uses non-optional Double for coordinates in Domain
            let lat1 = store1.latitude
            let lot1 = store1.longitude
            let lat2 = store2.latitude
            let lot2 = store2.longitude
            
            let loc1 = CLLocation(latitude: lat1, longitude: lot1)
            let loc2 = CLLocation(latitude: lat2, longitude: lot2)
            
            return clientLocation.distance(from: loc1) < clientLocation.distance(from: loc2)
        })
    }
}
