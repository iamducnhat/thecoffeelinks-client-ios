//
//  ContentView.swift
//  thecoffeelinks-native-swift
//
//  Main app routing with STRICT AUTH GATE enforcement
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // Manage Splash transition locally
    @State private var isSplashFinished = false
    
    var body: some View {
        ZStack(alignment: .top) {
            if !isSplashFinished {
                // 0. Splash Screen (Always First)
                SplashScreen(isActive: $isSplashFinished)
            } else if !authViewModel.isAuthenticated {
                // 1. Mandatory Auth Gate
                // User MUST be logged in to proceed.
                LoginView(isPresentedModally: false)
                    .transition(.opacity)
            } else if !appState.isOnboardingCompleted || !appState.isInitialSetupCompleted {
                // 2. Onboarding & Setup Flow
                // Combined flow: Carousel -> Setup
                OnboardingFlowView()
            } else {
                // 3. Main App
                MainTabView()
            }
        }
        .onAppear {
            authViewModel.checkSession()
        }
        .animation(.easeInOut, value: isSplashFinished)
        .animation(.easeInOut, value: appState.isOnboardingCompleted)
    }
}

// Preview disabled - requires environment setup
