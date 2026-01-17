import Foundation
import Combine

class DependencyContainer: ObservableObject {
    static let shared = DependencyContainer()
    
    // MARK: - Core Services
    private(set) lazy var keychainManager = KeychainManager()
    private(set) lazy var userPreferences = UserPreferencesManager()
    private(set) lazy var networkService = NetworkService(keychainManager: keychainManager)
    private(set) lazy var cacheService = CacheService()
    private(set) lazy var hapticManager = HapticManager()
    private(set) lazy var locationManager = LocationManager()
    private(set) lazy var imageCache = ImageCache()
    private(set) lazy var logger = Logger()
    
    // MARK: - Repositories
    private(set) lazy var authRepository = AuthRepository(networkService: networkService, keychainManager: keychainManager)
    private(set) lazy var productRepository = ProductRepository(networkService: networkService, cacheService: cacheService)
    private(set) lazy var orderRepository = OrderRepository(networkService: networkService)
    private(set) lazy var deliveryRepository = DeliveryRepository(networkService: networkService)
    private(set) lazy var storeRepository = StoreRepository(networkService: networkService)
    private(set) lazy var socialRepository = SocialRepository(networkService: networkService)
    private(set) lazy var userRepository = UserRepository(networkService: networkService)
    private(set) lazy var voucherRepository = VoucherRepository(networkService: networkService)
    private(set) lazy var favoritesRepository = FavoritesRepository(networkService: networkService)
    private(set) lazy var predictionRepository = PredictionRepository()
    
    // MARK: - Services
    private(set) lazy var analyticsService = AnalyticsService()
    
    private init() {}
    
    func initialize() async {
        // Pre-warm services
        _ = keychainManager
        _ = networkService
        
        // Check auth state
        if let token = keychainManager.getAccessToken() {
            await networkService.setAuthToken(token)
        }
    }
}
