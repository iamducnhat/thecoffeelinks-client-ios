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
            } else if !appState.isOnboardingCompleted || !appState.isInitialSetupCompleted {
                // 1. Onboarding & Setup Flow
                // Combined flow: Carousel -> Login (if needed) -> Setup
                OnboardingFlowView()
            } else {
                // 2. Main App
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
