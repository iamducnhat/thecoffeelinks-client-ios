//
//  OnboardingFlowView.swift
//  thecoffeelinks-client-ios
//
//  Orchestrates the Onboarding Sequence
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep: OnboardingStep = .carousel
    
    enum OnboardingStep {
        case carousel
        case setup
    }
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .carousel:
                ValuePropositionCarousel {
                    withAnimation {
                        currentStep = .setup
                    }
                }
                .transition(.opacity)
                
            case .setup:
                InitialSetupView()
                    .transition(.opacity)
                    // InitialSetupView manages its own completion via AppStorage binding
                    // But we might want to observe it to dismiss parent if needed, 
                    // though ContentView handles that via AppState.
                    // The InitialSetupView updates AppStorage("isInitialSetupCompleted"),
                    // and ContentView observes appState.
                    // effectively, once setup is done, ContentView switches to MainTabView.
            }
        }
    }
}
