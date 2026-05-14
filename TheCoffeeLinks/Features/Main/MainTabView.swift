//
//  MainTabView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cartViewModel: CartViewModel // Injected from parent
    @EnvironmentObject var authViewModel: AuthViewModel // Injected from parent
    @EnvironmentObject var appFlowController: AppFlowController
    
    // Use factory methods for consistent DI
    @StateObject private var menuViewModel: MenuViewModel
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var storesViewModel: StoresViewModel
    @StateObject private var trackingViewModel: OrderTrackingViewModel
    @State private var hasRefreshedAuthenticatedContent = false
    
    init() {
        let container = DependencyContainer.shared
        _menuViewModel = StateObject(wrappedValue: container.makeMenuViewModel())
        _homeViewModel = StateObject(wrappedValue: container.makeHomeViewModel())
        _profileViewModel = StateObject(wrappedValue: container.makeProfileViewModel())
        _storesViewModel = StateObject(wrappedValue: container.makeStoresViewModel())
        _trackingViewModel = StateObject(wrappedValue: container.makeOrderTrackingViewModel())
        
        // Tab bar appearance moved to `configureTabBarAppearance()` to ensure
        // UIKit color conversions run on the main actor (avoid SwiftUI render threads).
    }
    
    var body: some View {
        // Wire up ProfileViewModel with AuthViewModel on first render
        let _ = {
            if profileViewModel.authViewModel == nil {
                profileViewModel.authViewModel = authViewModel
            }
        }()
        // Conditional Support for iOS 26 Bottom Accessory
        if #available(iOS 26.1, *) {
            tabContent
                .tabViewBottomAccessory(isEnabled: !cartViewModel.isEmpty) {
                    CartMonitor()
                        .environmentObject(menuViewModel)
                }
                .tabBarMinimizeBehavior(.onScrollDown)
                .task {
                    // Startup Priority Queue
                    // 1. Home (High) - loads events, vouchers, products, predictions
                    await homeViewModel.load()
                    
                    // 2. Menu (Medium) - Must refresh even if not opened
                    Task(priority: .medium) {
                        await menuViewModel.load(
                            storeId: storesViewModel.selectedStore?.id ?? DependencyContainer.shared.userPreferences.selectedStoreId
                        )
                    }
                    // NOTE: getCurrentUser() is already called by AppFlowController.validateAuthState()
                    // Vouchers are already fetched by HomeViewModel.load() → loadVouchers()
                    // No need to duplicate those calls here.
                }
                .onChange(of: appFlowController.currentState) { state in
                    Task { await handleAppFlowStateChange(state) }
                }
        } else {
            ZStack(alignment: .bottom) {
                tabContent
                
                // Global Floating Cart (Fallback)
                if !cartViewModel.isEmpty {
                    CartMonitor()
                        .id("CartMonitor")
                        .environmentObject(menuViewModel)
                        .padding(.bottom, 50) // Lift above TabBar (approx 49pt standard height)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .task {
                await homeViewModel.load()
                Task(priority: .medium) {
                    await menuViewModel.load(
                        storeId: storesViewModel.selectedStore?.id ?? DependencyContainer.shared.userPreferences.selectedStoreId
                    )
                }
                // NOTE: getCurrentUser() is already called by AppFlowController.validateAuthState()
                // Vouchers are already fetched by HomeViewModel.load() → loadVouchers()
            }
            .onChange(of: appFlowController.currentState) { state in
                Task { await handleAppFlowStateChange(state) }
            }
        }
    }

    private var selectedMenuStoreId: String? {
        storesViewModel.selectedStore?.id ?? DependencyContainer.shared.userPreferences.selectedStoreId
    }

    @MainActor
    private func handleAppFlowStateChange(_ state: AppFlowState) async {
        switch state {
        case .ready:
            guard !hasRefreshedAuthenticatedContent else { return }
            hasRefreshedAuthenticatedContent = true

            async let cartRefresh: Void = cartViewModel.fetchCart()
            async let menuRefresh: Void = menuViewModel.refresh(storeId: selectedMenuStoreId)
            async let homeRefresh: Void = homeViewModel.refresh()
            _ = await (cartRefresh, menuRefresh, homeRefresh)

        case .guestReady, .loggedOut:
            hasRefreshedAuthenticatedContent = false

        default:
            break
        }
    }

    @MainActor
    static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(BaseViewColor.background)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(BaseViewColor.textSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [:]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(BaseViewColor.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [:]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    @ViewBuilder
    var tabContent: some View {
        TabView(selection: $appState.selectedTab) {
            // Home Tab
            HomeView()
                .environmentObject(menuViewModel)
                .environmentObject(homeViewModel)
                .environmentObject(trackingViewModel)
                .tabItem {
                    Image("home").renderingMode(.template)
                }
                .tag(0)
            
            // Menu Tab
            NavigationStack {
                MenuView()
                    .environmentObject(menuViewModel)
                    .environmentObject(storesViewModel)
            }
            .tabItem {
                Image("bag").renderingMode(.template)
            }
            .tag(1)
            
            // Stores Tab
            NavigationStack {
                StoresView()
                    .environmentObject(storesViewModel)
            }
            .tabItem {
                 Image("store").renderingMode(.template)
            }
            .tag(2)
            
            // Promotions Tab
            PromotionsView()
                .environmentObject(profileViewModel)
            .tabItem {
                Image("gift").renderingMode(.template)
            }
            .tag(3)
            
            // Profile Tab
            NavigationStack {
                ProfileView()
                    .environmentObject(profileViewModel)
            }
            .tabItem {
                Image("menu").renderingMode(.template)
            }
            .tag(4)
        }
        .tint(BaseViewColor.accent)
        .fullScreenCover(isPresented: $appState.showCheckout) {
            CheckoutView()
                .environmentObject(menuViewModel)
        }
        .onAppear {
            Task { @MainActor in
                Self.configureTabBarAppearance()
            }
        }
    }
}
