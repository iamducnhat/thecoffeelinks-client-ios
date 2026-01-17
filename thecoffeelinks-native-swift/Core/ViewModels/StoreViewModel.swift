import Foundation
import Combine
import CoreLocation

class StoreViewModel: BaseViewModel {
    private let storeRepository: StoreRepository
    private let locationManager: LocationManager
    
    @Published var stores: [Store] = []
    @Published var nearestStore: Store?
    @Published var selectedStore: Store?
    
    init(storeRepository: StoreRepository, locationManager: LocationManager) {
        self.storeRepository = storeRepository
        self.locationManager = locationManager
        super.init()
    }
    
    func loadStores() {
        withLoading {
            let fetched = try await self.storeRepository.getStores()
            await MainActor.run {
                self.stores = fetched
                self.updateNearest()
            }
        }
    }
    
    func selectStore(_ store: Store) {
        self.selectedStore = store
        DependencyContainer.shared.userPreferences.selectedStoreId = store.id
    }
    
    private func updateNearest() {
        guard let loc = locationManager.location, !stores.isEmpty else { return }
        
        let sorted = stores.sorted { s1, s2 in
            let loc1 = CLLocation(latitude: s1.latitude, longitude: s1.longitude)
            let loc2 = CLLocation(latitude: s2.latitude, longitude: s2.longitude)
            return loc.distance(from: loc1) < loc.distance(from: loc2)
        }
        
        self.nearestStore = sorted.first
    }
    
    func filteredStores(searchText: String) -> [Store] {
        if searchText.isEmpty { return stores }
        return stores.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.address.localizedCaseInsensitiveContains(searchText) }
    }
}
