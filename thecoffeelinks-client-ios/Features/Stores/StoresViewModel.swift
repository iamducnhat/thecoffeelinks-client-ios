//
//  StoresViewModel.swift
//  thecoffeelinks-client-ios
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class StoresViewModel: ObservableObject {
    @Published var stores: [Store] = []
    @Published var selectedStore: Store?
    @Published var nearbyStores: [Store] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchQuery = ""
    
    private let userRepository: UserRepositoryProtocol
    private let locationService: LocationServiceProtocol
    private let refreshCoordinator: ContentRefreshCoordinator
    private var cancellables = Set<AnyCancellable>()
    
    init(userRepository: UserRepositoryProtocol, locationService: LocationServiceProtocol, refreshCoordinator: ContentRefreshCoordinator) {
        self.userRepository = userRepository
        self.locationService = locationService
        self.refreshCoordinator = refreshCoordinator
        loadLastSelectedStore()
        setupSearch()
    }
    
    var filteredStores: [Store] {
        guard !searchQuery.isEmpty else { return nearbyStores }
        return nearbyStores.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.address.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    func load() async {
        // 1. Cache
        if let cached = await userRepository.getCachedStores() {
            self.stores = cached
            await loadNearbyStores()
        }
        
        // 2. Refresh
        await refreshCoordinator.schedule(id: "stores_refresh", priority: .medium) { [weak self] in
            await self?.performRefresh()
        }
    }
    
    private func performRefresh() async {
        isLoading = true
        error = nil
        do {
            let location = await locationService.currentLocation
            stores = try await userRepository.refreshStores(
                latitude: location?.latitude,
                longitude: location?.longitude
            )
            await loadNearbyStores()
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    func loadNearbyStores() async {
        guard let location = await locationService.currentLocation else {
            nearbyStores = stores
            return
        }
        
        let storesWithDistance = stores.map { store -> (Store, CLLocationDistance) in
            let storeLocation = CLLocation(latitude: store.latitude, longitude: store.longitude)
            let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            let distance = userLocation.distance(from: storeLocation)
            return (store, distance)
        }
        
        nearbyStores = storesWithDistance
            .sorted { (first, second) -> Bool in
                // 1. Sort by Status (Open > Closed)
                if first.0.isCurrentlyOpen != second.0.isCurrentlyOpen {
                    return first.0.isCurrentlyOpen
                }
                // 2. Sort by Distance
                return first.1 < second.1
            }
            .map { $0.0 }
    }
    
    func selectStore(_ store: Store) {
        selectedStore = store
        UserDefaults.standard.set(store.id, forKey: "lastSelectedStoreId")
    }
    
    private func loadLastSelectedStore() {
        guard let id = UserDefaults.standard.string(forKey: "lastSelectedStoreId") else { return }
        Task {
            await load()
            selectedStore = stores.first { $0.id == id }
        }
    }
    
    private func setupSearch() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func getDistance(to store: Store) async -> String? {
        guard let location = await locationService.currentLocation else { return nil }
        let storeLocation = CLLocation(latitude: store.latitude, longitude: store.longitude)
        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let distance = userLocation.distance(from: storeLocation) / 1000
        return String(format: "%.1f km", distance)
    }
}
