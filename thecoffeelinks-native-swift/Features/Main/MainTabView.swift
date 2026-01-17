//
//  MainTabView.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var menuViewModel = MenuViewModel(
        productRepository: DependencyContainer.shared.productRepository,
        cacheService: DependencyContainer.shared.cacheService
    )
    @StateObject private var homeViewModel = HomeViewModel(
        productRepository: DependencyContainer.shared.productRepository,
        favoritesRepository: DependencyContainer.shared.favoritesRepository,
        predictionRepository: DependencyContainer.shared.predictionRepository,
        userRepository: DependencyContainer.shared.userRepository,
        analyticsService: DependencyContainer.shared.analyticsService,
        networkService: DependencyContainer.shared.networkService
    )
    @StateObject private var profileViewModel = ProfileViewModel(
        userRepository: DependencyContainer.shared.userRepository,
        voucherRepository: DependencyContainer.shared.voucherRepository,
        socialRepository: DependencyContainer.shared.socialRepository,
        authRepository: DependencyContainer.shared.authRepository
    )
    @StateObject var networkViewModel = NetworkViewModel(
        socialRepository: DependencyContainer.shared.socialRepository,
        locationManager: DependencyContainer.shared.locationManager
    )
    
    init() {
        // Receipt-style tab bar customization
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.backgroundPaper)
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.textMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor(Color.textMuted)
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.textInk)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor(Color.textInk)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Home Tab
            HomeView()
                .environmentObject(menuViewModel)
                .environmentObject(homeViewModel)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            // Menu Tab
            NavigationStack {
                MenuView()
                    .environmentObject(menuViewModel)
            }
            .tabItem {
                Label("Menu", systemImage: "square.grid.2x2")
            }
            .tag(1)
            
            // Network Tab
            NavigationStack {
                NetworkView()
                    .environmentObject(networkViewModel)
            }
            .tabItem {
                Label("Space", systemImage: "person.3")
            }
            .tag(2)
            
            // Profile Tab
            NavigationStack {
                ProfileView()
                    .environmentObject(profileViewModel)
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(3)
        }
        .tint(Color.textInk)
    }
}
