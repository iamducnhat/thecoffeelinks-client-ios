//
//  InitialSetupView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
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
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                Rectangle()
                    .fill(BaseViewColor.accent)
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
        VStack(spacing: BaseViewLayout.spacingXL) {
            Spacer()
            
            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                Text("Permissions")
                    .textCase(.uppercase)
                    .font(BaseViewFont.monoBody)
                    .foregroundStyle(BaseViewColor.accent)
                
                Text("Required Access")
                    .font(BaseViewFont.displayTitle)
                    .foregroundStyle(BaseViewColor.textPrimary)
                
                Text("To facilitate localized detection and order updates, the following permissions are required.")
                    .font(BaseViewFont.body)
                    .foregroundStyle(BaseViewColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            
            VStack(spacing: BaseViewLayout.spacing) {
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
                    .font(BaseViewFont.monoCTA)
                    .foregroundStyle(BaseViewColor.background)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(BaseViewColor.accent)
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
                    .fill(isGranted ? BaseViewColor.semanticSuccess.opacity(0.1) : BaseViewColor.surface)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(isGranted ? "check" : icon)
                            .font(.system(size: 16))
                            .foregroundColor(isGranted ? BaseViewColor.semanticSuccess : BaseViewColor.textSecondary)
                    }
                    .overlay(Circle().strokeBorder(isGranted ? BaseViewColor.semanticSuccess : BaseViewColor.border, lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BaseViewFont.headline)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    Text(subtitle)
                        .font(BaseViewFont.uiCaption)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
                
                Spacer()
                
                if !isGranted {
                    Text("ALLOW")
                        .font(BaseViewFont.monoBody)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(BaseViewColor.accent, lineWidth: 1)
                        )
                        .foregroundColor(BaseViewColor.accent)
                }
            }
            .padding(16)
            .background(BaseViewColor.background)
            .overlay(
                RoundedRectangle(cornerRadius: BaseViewLayout.cornerRadius, style: BaseViewLayout.cornerStyle)
                    .strokeBorder(isGranted ? BaseViewColor.semanticSuccess : BaseViewColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.cornerRadius, style: BaseViewLayout.cornerStyle))
        }
        .disabled(isGranted)
    }
}
