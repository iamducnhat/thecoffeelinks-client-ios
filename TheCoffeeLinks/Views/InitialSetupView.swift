//
//  InitialSetupView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import CoreLocation

struct InitialSetupView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var storeViewModel: StoreViewModel
    @EnvironmentObject private var appFlowController: AppFlowController
    
    @State private var isLocationAuthorized = false
    @State private var isNotificationAuthorized = false
    
    var body: some View {
        ZStack {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                Rectangle()
                    .fill(Color.primaryEspresso)
                    .frame(height: 2)
                .padding(.top, 24)
                .padding(.horizontal, 24)
                
                permissionsStep
            }
        }
        .onAppear {
            checkCurrentPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkCurrentPermissions()
        }
    }
    
    private func checkCurrentPermissions() {
        // Use CLLocationManager authorizationStatus directly for accuracy
        let status = CLLocationManager().authorizationStatus
        DispatchQueue.main.async {
            self.isLocationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isAuthorized = settings.authorizationStatus == .authorized
            DispatchQueue.main.async {
                self.isNotificationAuthorized = isAuthorized
            }
        }
    }
    
    // MARK: - Step 1: Permissions
    private var permissionsStep: some View {
        VStack(spacing: AppLayout.spacingXL) {
            Spacer()
            
            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                Text("Permissions")
                    .textCase(.uppercase)
                    .font(AppFont.monoBody)
                    .foregroundStyle(Color.primaryEspresso)
                
                Text("Required Access")
                    .font(AppFont.displayTitle)
                    .foregroundStyle(Color.textInk)
                
                Text("To facilitate localized detection and order updates, the following permissions are required.")
                    .font(AppFont.body)
                    .foregroundStyle(Color.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            
            VStack(spacing: AppLayout.spacing) {
                PermissionTile(
                    title: "Location Services",
                    subtitle: "Nearby store detection",
                    isGranted: isLocationAuthorized,
                    icon: "map_pin"
                ) {
                    requestLocationPermission()
                }
                
                PermissionTile(
                    title: "Notifications",
                    subtitle: "Order status updates",
                    isGranted: isNotificationAuthorized,
                    icon: "bell"
                ) {
                    requestNotificationPermission()
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button {
                completeSetup()
            } label: {
                Text("Continue")
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.backgroundPaper)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func requestLocationPermission() {
        Task {
            await storeViewModel.requestLocationAuthorization()
            // The system prompt logic is handled by iOS. 
            // We refresh when the app returns from the prompt.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                checkCurrentPermissions()
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isNotificationAuthorized = granted
                checkCurrentPermissions()
            }
        }
    }
    
    private func completeSetup() {
        withAnimation {
            // Both must be true for ContentView to proceed to MainTabView
            appState.isOnboardingCompleted = true
            appState.isInitialSetupCompleted = true
            
            // Notify AppFlowController
            appFlowController.markOnboardingCompleted()
        }
    }
}

// MARK: - Components

struct PermissionTile: View {
    let title: String
    let subtitle: String
    let isGranted: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(isGranted ? Color.semanticSuccess.opacity(0.1) : Color.surfaceCard)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(isGranted ? "check" : icon)
                            .font(.system(size: 16))
                            .foregroundColor(isGranted ? Color.semanticSuccess : Color.textMuted)
                    }
                    .overlay(Circle().strokeBorder(isGranted ? Color.semanticSuccess : Color.border, lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.headline)
                        .foregroundStyle(Color.textInk)
                    Text(subtitle)
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.textMuted)
                }
                
                Spacer()
                
                if !isGranted {
                    Text("ALLOW")
                        .font(AppFont.monoBody)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color.primaryEspresso, lineWidth: 1)
                        )
                        .foregroundColor(Color.primaryEspresso)
                }
            }
            .padding(16)
            .background(Color.backgroundPaper)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .strokeBorder(isGranted ? Color.semanticSuccess : Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        }
        .disabled(isGranted)
    }
}

