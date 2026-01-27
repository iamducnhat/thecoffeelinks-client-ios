import Foundation
import CoreLocation

// Note: StoreRepository should be in Data layer, but currently located in Core/Repositories
final class StoreRepository: StoreRepositoryProtocol, SyncableDomain, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    private let storeStorage: StoreStorageProtocol
    private let syncManager: SyncManagerProtocol
    
    var domainKey: String { "store_status" }
    
    init(networkService: NetworkServiceProtocol, 
         storeStorage: StoreStorageProtocol = StoreStorage(),
         syncManager: SyncManagerProtocol = DependencyContainer.shared.syncManager) {
        self.networkService = networkService
        self.storeStorage = storeStorage
        self.syncManager = syncManager
        
        self.syncManager.register(domain: self)
    }
    
    func sync(reason: SyncReason) async {
        _ = try? await refreshStores()
    }
    
    func getStores() async throws -> [Store] {
        if let local = storeStorage.loadStores() {
            // Background refresh if stale? Or just return local and let syncManager handle periodic refresh?
            // "Load immediately" -> return local.
            Task { _ = try? await refreshStores() }
            return local
        }
        return try await refreshStores()
    }
    
    func refreshStores() async throws -> [Store] {
        let response: StoresResponse = try await networkService.get("/api/stores", queryItems: nil)
        
        storeStorage.saveStores(response.stores)
        return response.stores
    }
    
    func getStore(id: String) async throws -> Store {
        // Try local first from list?
        if let stores = storeStorage.loadStores(), let store = stores.first(where: { $0.id == id }) {
            return store
        }
        let response: StoreResponse = try await networkService.get("/api/stores/\(id)", queryItems: nil)
        return response.store
    }
    
    func getNearestStore(latitude: Double, longitude: Double) async throws -> Store? {
        // Use local list
        let allStores: [Store] = try await getStores()
        let clientLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        return allStores.min(by: { store1, store2 in
            let loc1 = CLLocation(latitude: store1.latitude, longitude: store1.longitude)
            let loc2 = CLLocation(latitude: store2.latitude, longitude: store2.longitude)
            return clientLocation.distance(from: loc1) < clientLocation.distance(from: loc2)
        })
    }
}

