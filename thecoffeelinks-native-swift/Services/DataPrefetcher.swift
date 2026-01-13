import Foundation
import Combine

@MainActor
class DataPrefetcher: ObservableObject {
    static let shared = DataPrefetcher()
    @Published var isReady = false
    
    private let storeService = StoreService()
    private let eventService = EventService()
    private let voucherService = VoucherService()
    private let productService = ProductService()
    private let menuClient = APIClient.shared 
    private let orderService = OrderService()
    
    // Check if we need to do a blocking fetch (i.e. first run)
    var needsInitialFetch: Bool {
        // If we don't have menu or stores, consider it a fresh install/cache clear
        return !CacheManager.shared.hasCachedData(for: "menu_cache") || 
               !CacheManager.shared.hasCachedData(for: "stores_cache")
    }
    
    func prefetchAll() async {
        // Run in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchStores() }
            group.addTask { await self.fetchEvents() }
            group.addTask { await self.fetchMenu() }
            group.addTask { await self.fetchProducts() }
            group.addTask { await self.fetchVouchers() }
            // Orders might require auth, so we skip or handle cautiously
        }
        
        self.isReady = true
    }
    
    private func fetchStores() async {
        try? await {
            let data = try await storeService.getStores()
            await CacheManager.shared.save(data, for: "stores_cache")
        }()
    }
    
    private func fetchEvents() async {
        try? await {
            let data = try await eventService.getEvents()
            await CacheManager.shared.save(data, for: "events_cache")
        }()
    }
    
    private func fetchMenu() async {
        try? await {
            let data: MenuResponse = try await menuClient.get("api/menu")
             await CacheManager.shared.save(data, for: "menu_cache")
        }()
    }
    
    private func fetchProducts() async {
         try? await {
            let data = try await productService.getProducts()
            await CacheManager.shared.save(data, for: "home_products_cache")
        }()
    }
    
    private func fetchVouchers() async {
         try? await {
            let data = try await voucherService.getVouchers()
            await CacheManager.shared.save(data, for: "vouchers_cache")
            await CacheManager.shared.save(data, for: "home_vouchers_cache")
        }()
    }
}
