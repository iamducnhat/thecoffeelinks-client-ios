import SwiftUI
import Combine

@main
struct thecoffeelinks_client_iosApp: App {
    // Shared Singletons - Use .shared if init is private, or just use shared instance directly
    @StateObject private var appState = AppState()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var authViewModel = AuthViewModel(authRepository: DependencyContainer.shared.authRepository)
    @StateObject private var cartViewModel = CartViewModel(
        deliveryRepository: DependencyContainer.shared.deliveryRepository,
        voucherRepository: DependencyContainer.shared.voucherRepository,
        hapticService: DependencyContainer.shared.hapticManager
    )
    @StateObject private var storeViewModel = StoreViewModel(
        storeRepository: DependencyContainer.shared.storeRepository,
        locationManager: DependencyContainer.shared.locationManager
    )
    @StateObject private var deliveryViewModel = DeliveryViewModel(
        deliveryRepository: DependencyContainer.shared.deliveryRepository,
        locationService: DependencyContainer.shared.locationManager
    )
    
    // Core Dependencies injected via environment
    // Use shared instance for repositories if they are singletons or created once
    private let dependencyContainer = DependencyContainer.shared
    
    init() {
        checkFreshInstall()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(networkMonitor)
                .environmentObject(authViewModel)
                .environmentObject(cartViewModel)
                .environmentObject(storeViewModel)
                .environmentObject(deliveryViewModel)
                .environmentObject(dependencyContainer.userPreferences) // Inject preferences
                .environmentObject(dependencyContainer.networkService) // Inject NetworkService
                .task {
                    // Initialize core services (load tokens, pre-warm cache)
                    await dependencyContainer.initialize()
                }
        }
    }
    
    private func checkFreshInstall() {
        let userDefaults = UserDefaults.standard
        let hasRunBeforeKey = "hasRunBefore_v1.0"
        
        if !userDefaults.bool(forKey: hasRunBeforeKey) {
            print("🚨 Fresh Install Detected! Cleaning up...")
            
            // 1. Clear Keychain (Auth Token)
            dependencyContainer.keychainManager.deleteAccessToken()
            
            // 2. Clear Disk Cache (CacheService)
            Task {
                await dependencyContainer.cacheService.clear()
            }
            
            // 3. Set Flag
            userDefaults.set(true, forKey: hasRunBeforeKey)
        }
    }
}

// AppState moved to separate file for clarity
// ContentView is in ContentView.swift - single source of truth for app routing
