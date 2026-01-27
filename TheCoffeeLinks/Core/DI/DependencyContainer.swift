import Foundation
import Combine

class DependencyContainer: ObservableObject {
    static let shared = DependencyContainer()
    
    // MARK: - Core Services
    private(set) lazy var keychainManager = KeychainManager()
    private(set) lazy var userPreferences = UserPreferencesManager()
    private(set) lazy var networkService = NetworkService(keychainManager: keychainManager)
    
    // Config Extraction (Redundant but consistent with NetworkService logic)
    private var config: NSDictionary? {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            return NSDictionary(contentsOfFile: path)
        }
        return nil
    }
    
    private var apiBaseURL: String {
        (config?["API_BASE_URL"] as? String)?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "https://api.thecoffeelinksvn.com"
    }
    
    // Extracted from Config or Fallback to known project
    private var supabaseURL: String {
        (config?["SUPABASE_URL"] as? String)?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "https://ggikmpqyhkfhctwqbytk.supabase.co"
    }
    
    // Allow overriding from Config if present, otherwise default to known anon key or empty (will require auth)
    private var supabaseAnonKey: String {
        config?["SUPABASE_ANON_KEY"] as? String ?? ""
    }
    
    private(set) lazy var realtimeService = RealtimeService(baseURL: supabaseURL, apiKey: supabaseAnonKey)
    
    private(set) lazy var cacheService = CacheService()
    private(set) lazy var hapticManager = HapticManager()
    private(set) lazy var locationManager = LocationManager()
    private(set) lazy var imageCache = ImageCache()
    private(set) lazy var refreshCoordinator = ContentRefreshCoordinator()
    private(set) lazy var syncManager = SyncManager(syncRepository: syncRepository)
    private(set) lazy var logger = Logger()
    
    // MARK: - Repositories
    private(set) lazy var authRepository = AuthRepository(networkService: networkService, keychainManager: keychainManager)
    private(set) lazy var productRepository = ProductRepository(networkService: networkService, cacheService: cacheService, syncManager: syncManager)
    private(set) lazy var syncRepository = SyncRepository(networkService: networkService)
    private(set) lazy var orderRepository = OrderRepository(networkService: networkService)
    private(set) lazy var deliveryRepository = DeliveryRepository(networkService: networkService)
    private(set) lazy var storeRepository = StoreRepository(networkService: networkService)
    private(set) lazy var socialRepository = SocialRepository(networkService: networkService)
    private(set) lazy var userRepository = UserRepository(networkService: networkService)
    private(set) lazy var voucherRepository = VoucherRepository(networkService: networkService, cacheService: cacheService, syncManager: syncManager)
    private(set) lazy var favoritesRepository = FavoritesRepository(networkService: networkService, cacheService: cacheService)
    private(set) lazy var predictionRepository = PredictionRepository()

    // MARK: - Services
    private(set) lazy var analyticsService = AnalyticsService()
    private(set) lazy var predictionSyncService = PredictionSyncService(orderRepository: orderRepository, predictionRepository: predictionRepository)
    private(set) lazy var cartService = CartService(networkService: networkService)
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func initialize() async {
        // Pre-warm services
        _ = keychainManager
        _ = networkService
        _ = realtimeService
        
        // Check auth state
        if let token = keychainManager.getAccessToken() {
            let refreshToken = keychainManager.getRefreshToken()
            await networkService.setAuthSession(accessToken: token, refreshToken: refreshToken)
            
            // Set token for Realtime (must happen on main thread or be thread safe)
            realtimeService.setAuthToken(token)
            // Note: Realtime connection happens in ViewModel or on demand
        }
        
        // Subscribe to auth token changes to keep RealtimeService in sync
        await MainActor.run {
            networkService.$authToken
                .receive(on: RunLoop.main)
                .sink { [weak self] token in
                    guard let self = self else { return }
                    if let token = token {
                        self.realtimeService.setAuthToken(token)
                    } else {
                        self.realtimeService.disconnect()
                    }
                }
                .store(in: &cancellables)
        }
        
        // Initial sync of data versions
        do {
            try await syncManager.refreshVersions()
        } catch {
            print("⚠️ SyncManager initial refresh failed: \(error)")
        }
    }
}
