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
    
    // Search State
    @State private var searchText = ""
    
    var body: some View {
        Group {
            if authViewModel.state == .authenticated {
                NavigationStack {
                    if #available(iOS 26, *) {
                        TabView {
                            Tab("Home", image: "home") {
                                HomeView()
                            }
                            
                            Tab("Stores", image: "map_pin") {
                                StoresView()
                            }
                            
                            Tab("Network", image: "users") {
                                NetworkView()
                            }
                            
                            // Search Tab with role: .search
                            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                                SearchView(externalQuery: searchText)
                                    .searchable(text: $searchText)
                            }
                            
                            Tab("Orders", image: "coffee") {
                                OrdersView()
                            }
                        }
                        .tint(Color.coffeeDark)
                        .environmentObject(appState)
                    } else {
                        // Legacy Fallback for < iOS 26
                        TabView {
                            HomeView()
                                .tabItem {
                                    Label {
                                        Text("Home")
                                    } icon: {
                                        Image("home")
                                    }
                                }
                            
                            StoresView()
                                .tabItem {
                                    Label {
                                        Text("Stores")
                                    } icon: {
                                        Image("map_pin")
                                    }
                                }
                            
                            NetworkView()
                                .tabItem {
                                    Label {
                                        Text("Network")
                                    } icon: {
                                        Image("users")
                                    }
                                }
                            
                            OrdersView()
                                .tabItem {
                                    Label {
                                        Text("Orders")
                                    } icon: {
                                        Image("coffee")
                                    }
                                }
                        }
                        .tint(Color.coffeeDark)
                        .environmentObject(appState)
                    }
                }
            } else if authViewModel.state == .loading {
                ZStack {
                    Color.brandBackground.ignoresSafeArea()
                    ProgressView()
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            Task {
                await authViewModel.checkSession()
            }
        }
    }
}

#Preview {
    ContentView()
}
