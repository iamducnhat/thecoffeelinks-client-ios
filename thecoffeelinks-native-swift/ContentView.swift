//
//  ContentView.swift
//  thecoffeelinks-native-swift
//
//  Created by Nguyen Duc Nhat on 12/1/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @ObservedObject private var cartManager = CartManager.shared
    @StateObject private var prefetcher = DataPrefetcher.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared // Network Monitor
    
    // Search State
    @State private var searchText = ""
    @State private var isSetupLoading = false
    
    var body: some View {
        ZStack(alignment: .top) { // Change to ZStack for Overlay
            Group {
            if isSetupLoading && !prefetcher.isReady {
                // 0. Loading / Splash
                SplashLoadingView()
            } else if !appState.isOnboardingCompleted {
                // 1. Onboarding Flow (Strict)
                OnboardingView()
            } else if authViewModel.state != .authenticated {
                // 2. Authentication
                LoginView()
            } else if !appState.isInitialSetupCompleted {
                // 3. Initial Setup
                InitialSetupView()
            } else {
                // 4. Main App
                mainAppContent
            }
            }
            .onAppear {
                Task { await authViewModel.checkSession() }
            }
            
            // Offline Banner
            if !networkMonitor.isConnected {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("No Internet Connection")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(20)
                .padding(.top, 50) // Adjust for Safe Area
                .transition(.move(edge: .top))
                .animation(.easeInOut, value: networkMonitor.isConnected)
                .zIndex(999)
            }
        }
        .onAppear {
             if prefetcher.needsInitialFetch {
                 isSetupLoading = true
                 Task { await prefetcher.prefetchAll() }
             }
        }
    }
    
    // MARK: - Main App Content
    @ViewBuilder
    private var mainAppContent: some View {
        if #available(iOS 26, *) {
            TabView {
                // TAB 1: HOME (Discovery Hub)
                Tab("Home", image: "home") {
                    NavigationStack {
                        HomeView()
                    }
                }
                
                // TAB 2: ORDER (Transaction Engine)
                Tab("Order", image: "coffee") {
                    NavigationStack {
                        OrderTabView()
                    }
                }
                
                // TAB 3: SPACE (Location + Booking)
                Tab("Space", image: "map_pin") {
                    NavigationStack {
                        StoresView()
                    }
                }
                
                // TAB 4: CONNECT (Networking)
                Tab("Connect", image: "network") {
                    NavigationStack {
                        ConnectView()
                    }
                }
                
                // TAB 5: PROFILE (Control Center)
                Tab("Profile", image: "users") {
                    NavigationStack {
                        ProfileView()
                    }
                }
            }
            .tint(Color.forestCanopy)
            .environmentObject(appState)
            .modifier(CartAccessoryModifier(isEnabled: !cartManager.items.isEmpty))
            .tabBarMinimizeBehavior(.automatic)
            .withRefillPrompt()
        } else {
            // Legacy Fallback for < iOS 26
            ZStack(alignment: .bottom) {
                TabView {
                    HomeView()
                        .tabItem { Label("Home", image: "home") }
                    
                    OrderTabView()
                        .tabItem { Label("Order", image: "coffee") }
                    
                    StoresView()
                        .tabItem { Label("Space", image: "map_pin") }
                    
                    ConnectView()
                        .tabItem { Label("Connect", image: "network") }
                    
                    ProfileView()
                        .tabItem { Label("Profile", image: "users") }
                }
                .tint(Color.forestCanopy)
                .environmentObject(appState)
                
                CartFloater()
            }
        }
    }
}

#Preview {
    ContentView()
}
