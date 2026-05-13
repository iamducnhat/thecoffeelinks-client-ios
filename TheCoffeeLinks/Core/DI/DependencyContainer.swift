import Foundation
import Combine

class DependencyContainer: ObservableObject {
    static let shared = DependencyContainer()
    
    // MARK: - Core Services
    private(set) lazy var keychainManager = KeychainManager()
    private(set) lazy var userPreferences: UserPreferencesManager = {
        let manager = UserPreferencesManager()
        manager.configure(userRepository: userRepository, syncManager: syncManager)
        return manager
    }()
    private(set) lazy var networkService = NetworkService(keychainManager: keychainManager)
    
    // Config Extraction (Redundant but consistent with NetworkService logic)
    private var config: NSDictionary? {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            return NSDictionary(contentsOfFile: path)
        }
        return nil
    }
    
    private var apiBaseURL: String {
        (config?["API_BASE_URL"] as? String)?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "https://api.thecoffeelinks.vn"
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
    private(set) lazy var syncManager = SyncManager(syncRepository: syncRepository, keychainManager: keychainManager)
    private(set) lazy var logger = Logger()
    
    // MARK: - App Flow Controller
    private(set) lazy var appFlowController: AppFlowController = {
        AppFlowController(
            keychainManager: keychainManager,
            profileStorage: profileStorage,
            authRepository: authRepository
        )
    }()
    
    // MARK: - Repositories
    private(set) lazy var authRepository = AuthRepository(networkService: networkService, keychainManager: keychainManager)
    private(set) lazy var productRepository = ProductRepository(networkService: networkService, cacheService: cacheService, syncManager: syncManager)
    private(set) lazy var syncRepository = SyncRepository(networkService: networkService)
    private(set) lazy var orderRepository = OrderRepository(networkService: networkService)
    private(set) lazy var deliveryRepository = DeliveryRepository(networkService: networkService)
    private(set) lazy var storeRepository = StoreRepository(networkService: networkService, storeStorage: storeStorage, syncManager: syncManager)
    private(set) lazy var socialRepository = SocialRepository(networkService: networkService, storeStorage: storeStorage)
    private(set) lazy var userRepository = UserRepository(networkService: networkService, profileStorage: profileStorage, syncManager: syncManager)
    private(set) lazy var voucherRepository = VoucherRepository(networkService: networkService, profileStorage: profileStorage, syncManager: syncManager)
    private(set) lazy var favoritesRepository = FavoritesRepository(networkService: networkService, profileStorage: profileStorage)
    private(set) lazy var predictionRepository = PredictionRepository()

    // MARK: - Services
    private(set) lazy var analyticsService = AnalyticsService()
    private(set) lazy var predictionSyncService = PredictionSyncService(orderRepository: orderRepository, predictionRepository: predictionRepository)
    private(set) lazy var cartStorage = CartStorage()
    private(set) lazy var storeStorage = StoreStorage()
    private(set) lazy var profileStorage = ProfileStorage()
    private(set) lazy var cartService = CartService(networkService: networkService, cartStorage: cartStorage, productRepository: productRepository, keychainManager: keychainManager)
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - ViewModel Factory Methods
    
    @MainActor
    func makeCartViewModel() -> CartViewModel {
        CartViewModel(
            deliveryRepository: deliveryRepository,
            voucherRepository: voucherRepository,
            hapticService: hapticManager,
            cartService: cartService
        )
    }
    
    @MainActor
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            productRepository: productRepository,
            voucherRepository: voucherRepository,
            favoritesRepository: favoritesRepository,
            predictionRepository: predictionRepository,
            userRepository: userRepository,
            analyticsService: analyticsService,
            networkService: networkService,
            predictionSyncService: predictionSyncService,
            refreshCoordinator: refreshCoordinator
        )
    }
    
    @MainActor
    func makeMenuViewModel() -> MenuViewModel {
        MenuViewModel(
            productRepository: productRepository,
            cacheService: cacheService,
            refreshCoordinator: refreshCoordinator
        )
    }
    
    @MainActor
    func makeProfileViewModel() -> ProfileViewModel {
        let viewModel = ProfileViewModel(
            userRepository: userRepository,
            voucherRepository: voucherRepository,
            socialRepository: socialRepository,
            authRepository: authRepository,
            orderRepository: orderRepository,
            profileStorage: profileStorage,
            keychainManager: keychainManager
        )
        // Note: authViewModel should be set by the caller who has access to it
        return viewModel
    }
    
    @MainActor
    func makeStoresViewModel() -> StoresViewModel {
        StoresViewModel(
            storeRepository: storeRepository,
            locationService: locationManager,
            refreshCoordinator: refreshCoordinator
        )
    }
    
    @MainActor
    func makeOrderTrackingViewModel() -> OrderTrackingViewModel {
        OrderTrackingViewModel(
            orderRepository: orderRepository,
            realtimeService: realtimeService
        )
    }
    
    @MainActor
    func makeCheckoutViewModel() -> CheckoutViewModel {
        CheckoutViewModel(
            orderRepository: orderRepository,
            deliveryRepository: deliveryRepository,
            voucherRepository: voucherRepository,
            predictionRepository: predictionRepository,
            analyticsService: analyticsService,
            hapticService: hapticManager,
            orderStorage: OrderStorage()
        )
    }
    
    @MainActor
    func makeOrdersViewModel() -> OrdersViewModel {
        OrdersViewModel(repository: orderRepository)
    }
    
    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        let viewModel = AuthViewModel(authRepository: authRepository, profileStorage: profileStorage)
        // Wire up AppFlowController
        viewModel.appFlowController = appFlowController
        return viewModel
    }
    
    @MainActor
    func makeStoreViewModel() -> StoreViewModel {
        StoreViewModel(
            storeRepository: storeRepository,
            locationManager: locationManager
        )
    }
    
    @MainActor
    func makeDeliveryViewModel() -> DeliveryViewModel {
        DeliveryViewModel(
            deliveryRepository: deliveryRepository,
            locationService: locationManager
        )
    }
    
    /// Synchronous initialization - called before UI renders to prevent race conditions
    @MainActor
    func initializeSync() {
        debugLog("🚀 [DependencyContainer] Starting synchronous initialization")
        
        // Pre-warm services
        _ = keychainManager
        _ = networkService
        _ = realtimeService
        
        // Check auth state synchronously
        if let token = keychainManager.getAccessToken() {
            let refreshToken = keychainManager.getRefreshToken()
            // Set auth session synchronously on MainActor (no Task wrapper needed)
            networkService.setAuthSessionSync(accessToken: token, refreshToken: refreshToken)
            
            // Set token for Realtime
            realtimeService.setAuthToken(token)
        }
        
        // Initialize AppFlowController synchronously (already on MainActor)
        appFlowController.initializeSync()
        
        debugLog("✅ [DependencyContainer] Synchronous initialization complete")
    }
    
    /// Asynchronous initialization - called after UI renders for background tasks
    func initializeAsync() async {
        debugLog("🔄 [DependencyContainer] Starting asynchronous initialization")
        
        // Check if authenticated before subscribing to auth changes
        let isAuthenticated = keychainManager.getAccessToken() != nil
        
        if isAuthenticated {
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
            
            // Initial sync of data versions (only when authenticated)
            do {
                try await syncManager.refreshVersions()
            } catch {
                debugLog("⚠️ SyncManager initial refresh failed: \(error)")
            }
        } else {
            debugLog("⏭️ [DependencyContainer] Skipping auth-dependent initialization (guest mode)")
        }
        
        debugLog("✅ [DependencyContainer] Asynchronous initialization complete")
    }
    
    // DEPRECATED: Use initializeSync() + initializeAsync() instead
    func initialize() async {
        await initializeAsync()
    }
}
