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
    
    var body: some View {
        Group {
            if authViewModel.session != nil {
                TabView {
                    HomeView()
                        .tabItem {
                            Label {
                                Text("Home")
                            } icon: {
                                Image("home")
                            }
                        }
                    
                    EventsView()
                        .tabItem {
                            Label {
                                Text("Events")
                            } icon: {
                                Image("calendar")
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
                    
                    ProfileView()
                        .tabItem {
                            Label {
                                Text("Profile")
                            } icon: {
                                Image("user")
                            }
                        }
                }
                .tint(Color.coffeeDark) // Brand Tint
                .environmentObject(appState)
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
