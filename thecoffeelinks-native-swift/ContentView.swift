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
    
    // Search State
    @State private var searchText = ""
    
    var body: some View {
        Group {
            if authViewModel.state == .authenticated {
                if #available(iOS 26, *) {
                    TabView {
                        Tab("Home", image: "home") {
                            NavigationStack {
                                HomeView()
                            }
                        }
                        
                        Tab("Stores", image: "map_pin") {
                            NavigationStack {
                                StoresView()
                            }
                        }
                        
                        Tab("Network", image: "users") {
                            NavigationStack {
                                NetworkView()
                            }
                        }
                        
                        Tab("Search", systemImage: "magnifyingglass", role: .search) {
                            NavigationStack {
                                SearchView(enableInternalSearch: false)
                                    .searchable(text: $searchText)
                            }
                        }
                        
                        Tab("Orders", image: "coffee") {
                            NavigationStack {
                                OrdersView()
                            }
                        }
                    }
                    .tint(Color.coffeeDark)
                    .environmentObject(appState)
                    .modifier(CartAccessoryModifier(isEnabled: !cartManager.items.isEmpty))
                    .tabBarMinimizeBehavior(.automatic)
                } else {
                    // Legacy Fallback for < iOS 26
                    ZStack(alignment: .bottom) {
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
                        
                        CartFloater()
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
