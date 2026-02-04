import SwiftUI
import Combine

@main
struct TheCoffeeLinksApp: App {
    // Shared Singletons
    @StateObject private var appState = AppState()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    // Use factory methods for ViewModels
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var cartViewModel: CartViewModel
    @StateObject private var storeViewModel: StoreViewModel
    @StateObject private var deliveryViewModel: DeliveryViewModel
    
    // Core Dependencies
    private let dependencyContainer = DependencyContainer.shared
    
    init() {
        // Use factory methods for consistent DI
        let container = DependencyContainer.shared
        _authViewModel = StateObject(wrappedValue: container.makeAuthViewModel())
        _cartViewModel = StateObject(wrappedValue: container.makeCartViewModel())
        _storeViewModel = StateObject(wrappedValue: container.makeStoreViewModel())
        _deliveryViewModel = StateObject(wrappedValue: container.makeDeliveryViewModel())
        
        // CRITICAL: Initialize dependencies synchronously BEFORE UI renders
        // This prevents race conditions between auth check and UI routing
        container.initializeSync()
        
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
                .environmentObject(dependencyContainer.appFlowController) // Inject AppFlowController
                .task {
                    // Async initialization for background tasks (data sync, etc.)
                    await dependencyContainer.initializeAsync()
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
            dependencyContainer.keychainManager.deleteRefreshToken()
            
            // 2. Clear Disk Cache (CacheService)
            Task {
                await dependencyContainer.cacheService.clear()
            }
            
            // 3. Clear Cart Storage
            dependencyContainer.cartStorage.clearCart()
            
            // 4. Clear Profile Storage
            dependencyContainer.profileStorage.clearUser()
            
            // 5. Clear UserDefaults (onboarding, verification cache, etc.)
            userDefaults.removeObject(forKey: "isOnboardingCompleted")
            userDefaults.removeObject(forKey: "isInitialSetupCompleted")
            userDefaults.removeObject(forKey: "isPhoneVerified_cached")
            userDefaults.removeObject(forKey: "isPhoneVerified_timestamp")
            userDefaults.removeObject(forKey: "selectedStoreId")
            
            // 6. Set Flag
            userDefaults.set(true, forKey: hasRunBeforeKey)
            
            print("✅ Fresh install cleanup complete")
        }
    }
}

// AppState moved to separate file for clarity
// ContentView is in ContentView.swift - single source of truth for app routing
