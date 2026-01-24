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
    @State private var currentStep = 0
    @State private var selectedTaste: String?
    
    @State private var isLocationAuthorized = false
    @State private var isNotificationAuthorized = false
    
    var body: some View {
        ZStack {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(currentStep >= 0 ? Color.primaryEspresso : Color.border)
                        .frame(height: 2)
                    Rectangle()
                        .fill(currentStep >= 1 ? Color.primaryEspresso : Color.border)
                        .frame(height: 2)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                
                if currentStep == 0 {
                    permissionsStep
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else {
                    tasteQuizStep
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentStep)
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
            DispatchQueue.main.async {
                self.isNotificationAuthorized = (settings.authorizationStatus == .authorized)
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
            .padding(.horizontal, 24)
            
            VStack(spacing: AppLayout.spacing) {
                PermissionTile(
                    title: "Location Services",
                    subtitle: "Nearby store detection",
                    isGranted: isLocationAuthorized,
                    icon: "location.fill"
                ) {
                    requestLocationPermission()
                }
                
                PermissionTile(
                    title: "Notifications",
                    subtitle: "Order status updates",
                    isGranted: isNotificationAuthorized,
                    icon: "bell.fill"
                ) {
                    requestNotificationPermission()
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button {
                withAnimation {
                    currentStep = 1
                }
            } label: {
                Text("Continue")
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.backgroundPaper)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
            .padding(24)
            .padding(.bottom, 24)
        }
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
    
    // MARK: - Step 2: Taste Quiz
    private var tasteQuizStep: some View {
        VStack(spacing: AppLayout.spacingXL) {
            Spacer()
            
            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                Text("Taste Profile")
                    .textCase(.uppercase)
                    .font(AppFont.monoBody)
                    .foregroundStyle(Color.primaryEspresso)
                
                Text("Your Preference")
                    .font(AppFont.displayTitle)
                    .foregroundStyle(Color.textInk)
                
                Text("Help us optimize recommendations for your taste.")
                    .font(AppFont.body)
                    .foregroundStyle(Color.textMuted)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: AppLayout.spacing) {
                SelectableRow(
                    title: "Bold & Strong",
                    isSelected: selectedTaste == "Bold"
                ) { selectedTaste = "Bold" }
                
                SelectableRow(
                    title: "Fruity & Floral",
                    isSelected: selectedTaste == "Fruity"
                ) { selectedTaste = "Fruity" }
                
                SelectableRow(
                    title: "Smooth & Milky",
                    isSelected: selectedTaste == "Milky"
                ) { selectedTaste = "Milky" }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button {
                completeSetup()
            } label: {
                Text("Complete Setup")
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.backgroundPaper)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(selectedTaste == nil ? Color.textMuted : Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
            .disabled(selectedTaste == nil)
            .padding(24)
            .padding(.bottom, 24)
        }
    }
    
    private func completeSetup() {
        withAnimation {
            // Both must be true for ContentView to proceed to MainTabView
            appState.isOnboardingCompleted = true
            appState.isInitialSetupCompleted = true
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
                        Image(systemName: isGranted ? "checkmark" : icon)
                            .font(.system(size: 16))
                            .foregroundColor(isGranted ? Color.semanticSuccess : Color.textMuted)
                    }
                    .overlay(Circle().stroke(isGranted ? Color.semanticSuccess : Color.border, lineWidth: 1))
                
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
                                .stroke(Color.primaryEspresso, lineWidth: 1)
                        )
                        .foregroundColor(Color.primaryEspresso)
                }
            }
            .padding(16)
            .background(Color.backgroundPaper)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(isGranted ? Color.semanticSuccess : Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        }
        .disabled(isGranted)
    }
}

struct SelectableRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(Color.textInk)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.primaryEspresso)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.border)
                }
            }
            .padding(AppLayout.spacing)
            .background(isSelected ? Color.surfaceCard : Color.backgroundPaper)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(isSelected ? Color.primaryEspresso : Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        }
    }
}
