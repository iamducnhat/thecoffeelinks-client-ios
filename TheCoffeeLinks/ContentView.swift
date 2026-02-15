//
//  ContentView.swift
//  thecoffeelinks-client-ios
//
//  Main app routing with AppFlowController state machine
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var appFlowController: AppFlowController
    
    // Monitor app lifecycle for background/foreground transitions
    @Environment(\.scenePhase) private var scenePhase
    
    // Manage Splash transition locally
    @State private var isSplashFinished = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Route based on AppFlowController state
            switch appFlowController.currentState {
            case .launching, .checkingAuth:
                // Show splash while checking auth
                if !isSplashFinished {
                    SplashScreen(isActive: $isSplashFinished)
                } else {
                    // Checking auth, show loading or splash
                    SplashScreen(isActive: .constant(true))
                }
                
            case .loggedOut, .loggingIn, .error:
                // User must log in
                LoginView(isPresentedModally: false)
                    .transition(.opacity)
                
            case .pendingPhoneVerification:
                // User logged in but phone not verified
                PhoneVerificationView()
                    .transition(.opacity)
                
            case .onboarding, .loggedInIncompleteProfile:
                // Onboarding & setup flow
                OnboardingFlowView()
                    .transition(.opacity)
                
            case .guestReady, .ready:
                // Main app (guest mode or authenticated)
                MainTabView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Initialize flow controller synchronously first
            if !appFlowController.isInitialized {
                appFlowController.initializeSync()
            }
            
            // Then validate with server asynchronously
            Task {
                await appFlowController.validateAuthState()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(to: newPhase)
        }
        .animation(.easeInOut, value: isSplashFinished)
        .animation(.easeInOut, value: appFlowController.currentState)
    }
    
    private func handleScenePhaseChange(to newPhase: ScenePhase) {
        debugLog("🔄 [ContentView] Scene phase changed to: \(newPhase)")
        
        switch newPhase {
        case .active:
            // App became active - check if coming from background
            debugLog("✅ [ContentView] App became active")
            Task {
                await appFlowController.handleAppResume()
            }
            
        case .background:
            // App went to background - save state
            debugLog("💾 [ContentView] App backgrounded, saving state")
            saveAppState()
            
        case .inactive:
            // App became inactive (brief transition, e.g., control center)
            break
            
        @unknown default:
            break
        }
    }
    
    private func saveAppState() {
        // State is already persisted by AppFlowController and AppState
        // This is a placeholder for additional state saving if needed
    }
}

// Preview disabled - requires environment setup
