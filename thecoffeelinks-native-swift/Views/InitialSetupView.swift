//
//  InitialSetupView.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-14.
//

import SwiftUI
import CoreLocation

struct InitialSetupView: View {
    @AppStorage("isInitialSetupCompleted") private var isInitialSetupCompleted: Bool = false
    @State private var currentStep = 0
    @State private var selectedTaste: String?
    
    // Animation states
    @State private var isLocationAuthorized = false
    @State private var isNotificationAuthorized = false
    
    var body: some View {
        ZStack {
            Color.morningFog.ignoresSafeArea()
            
            VStack {
                // Progress Bar
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(currentStep >= 0 ? Color.forestCanopy : Color.neutral200)
                        .frame(height: 4)
                    Rectangle()
                        .fill(currentStep >= 1 ? Color.forestCanopy : Color.neutral200)
                        .frame(height: 4)
                }
                .padding(.top, 8)
                
                if currentStep == 0 {
                    permissionsStep
                        .transition(.move(edge: .leading))
                } else {
                    tasteQuizStep
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.easeInOut, value: currentStep)
        }
    }
    
    // MARK: - Step 1: Permissions
    private var permissionsStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Enable Full Experience")
                    .font(.brandSerif(28))
                    .foregroundStyle(Color.forestCanopy)
                
                Text("To find the nearest spot and never miss a coffee connection, we need a few permissions.")
                    .font(.brandSans(16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.neutral600)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                // Location Permission Tile
                PermissionTile(
                    icon: "location.fill",
                    title: "Location Access",
                    subtitle: "Find nearyby cafes & check-in",
                    isGranted: $isLocationAuthorized
                ) {
                    // In a real app, we'd call CLLocationManager here
                    // For now, we simulate authorization
                    withAnimation { isLocationAuthorized = true }
                }
                
                // Notification Permission Tile
                PermissionTile(
                    icon: "bell.badge.fill",
                    title: "Notifications",
                    subtitle: "Order updates & networking invites",
                    isGranted: $isNotificationAuthorized
                ) {
                    // Simulate auth
                    withAnimation { isNotificationAuthorized = true }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            LiquidGlassPrimaryButton(
                "Continue",
                isDisabled: !(isLocationAuthorized || isNotificationAuthorized) // Require at least one for demo flow? Or just let them pass
            ) {
                withAnimation {
                    currentStep = 1
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
    
    // MARK: - Step 2: Taste Quiz
    private var tasteQuizStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("What's Your Taste?")
                    .font(.brandSerif(28))
                    .foregroundStyle(Color.forestCanopy)
                
                Text("Help us recommend the perfect brew for your productive mornings.")
                    .font(.brandSans(16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.neutral600)
                    .padding(.horizontal)
            }
            
            // Taste Options Grid
            VStack(spacing: 12) {
                TasteOptionCard(
                    title: "Bold & Strong",
                    icon: "bolt.fill",
                    color: .coffeeRich,
                    isSelected: selectedTaste == "Bold"
                ) { selectedTaste = "Bold" }
                
                TasteOptionCard(
                    title: "Fruity & Floral",
                    icon: "leaf.fill",
                    color: .brandAccent,
                    isSelected: selectedTaste == "Fruity"
                ) { selectedTaste = "Fruity" }
                
                TasteOptionCard(
                    title: "Smooth & Milky",
                    icon: "drop.fill",
                    color: .sunRay,
                    isSelected: selectedTaste == "Milky"
                ) { selectedTaste = "Milky" }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            LiquidGlassPrimaryButton(
                "Complete Setup",
                isLoading: false,
                isDisabled: selectedTaste == nil
            ) {
                completeSetup()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
    
    private func completeSetup() {
        // Save taste preference logic here (e.g. UserDefault or API)
        withAnimation {
            isInitialSetupCompleted = true
        }
    }
}

// MARK: - Components

struct PermissionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isGranted ? Color.successGreen.opacity(0.1) : Color.neutral100)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: isGranted ? "checkmark" : icon)
                        .foregroundStyle(isGranted ? Color.successGreen : Color.forestCanopy)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.brandSans(16).weight(.semibold))
                        .foregroundStyle(Color.neutral900)
                    Text(subtitle)
                        .font(.brandSans(13))
                        .foregroundStyle(Color.neutral500)
                }
                
                Spacer()
                
                if !isGranted {
                    Text("Allow")
                        .font(.brandSans(14).weight(.medium))
                        .foregroundStyle(Color.forestCanopy)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.forestCanopy.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isGranted ? Color.successGreen : Color.neutral200, lineWidth: isGranted ? 1.5 : 1)
            )
        }
        .disabled(isGranted)
    }
}

struct TasteOptionCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.white.opacity(0.2) : color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.brandSans(16).weight(.medium))
                    .foregroundStyle(isSelected ? .white : .neutral800)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(16)
            .background(isSelected ? color : Color.white)
            .cornerRadius(12)
            .shadow(color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.05), radius: 8, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.neutral200, lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(), value: isSelected)
    }
}

#Preview {
    InitialSetupView()
}
