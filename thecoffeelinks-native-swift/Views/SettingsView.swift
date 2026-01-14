//
//  SettingsView.swift
//  thecoffeelinks-native-swift
//
//  App Settings per Blueprint P-007
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authViewModel = AuthViewModel.shared
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("locationEnabled") private var locationEnabled = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    
    var body: some View {
        List {
            // Account Section
            Section {
                NavigationLink {
                    EditProfileView()
                } label: {
                    settingRow(icon: "person.fill", title: "Edit Profile", color: .blue)
                }
                
                NavigationLink {
                    SavedAddressesView { _ in /* address selected */ }
                } label: {
                    settingRow(icon: "location.fill", title: "Saved Addresses", color: .green)
                }
                
                NavigationLink {
                    // Payment methods
                } label: {
                    settingRow(icon: "creditcard.fill", title: "Payment Methods", color: .purple)
                }
            } header: {
                Text("Account")
            }
            
            // Preferences Section
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    settingRow(icon: "bell.fill", title: "Push Notifications", color: .red)
                }
                .tint(Color.forestCanopy)
                
                Toggle(isOn: $locationEnabled) {
                    settingRow(icon: "location.fill", title: "Location Services", color: .blue)
                }
                .tint(Color.forestCanopy)
                
                Toggle(isOn: $hapticFeedback) {
                    settingRow(icon: "hand.tap.fill", title: "Haptic Feedback", color: .orange)
                }
                .tint(Color.forestCanopy)
            } header: {
                Text("Preferences")
            }
            
            // Support Section
            Section {
                NavigationLink {
                    // Help center
                } label: {
                    settingRow(icon: "questionmark.circle.fill", title: "Help Center", color: .teal)
                }
                
                NavigationLink {
                    // Contact us
                } label: {
                    settingRow(icon: "envelope.fill", title: "Contact Us", color: .indigo)
                }
                
                NavigationLink {
                    // Privacy policy
                } label: {
                    settingRow(icon: "hand.raised.fill", title: "Privacy Policy", color: .gray)
                }
                
                NavigationLink {
                    // Terms
                } label: {
                    settingRow(icon: "doc.text.fill", title: "Terms of Service", color: .gray)
                }
            } header: {
                Text("Support")
            }
            
            // App Info Section
            Section {
                HStack {
                    settingRow(icon: "info.circle.fill", title: "Version", color: .gray)
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(Color.neutral500)
                }
            } header: {
                Text("About")
            }
            
            // Logout Section
            Section {
                Button(role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func settingRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .cornerRadius(6)
            
            Text(title)
                .foregroundStyle(Color.forestCanopy)
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isSaving = false
    
    var body: some View {
        Form {
            Section {
                // Avatar
                HStack {
                    Spacer()
                    VStack {
                        Circle()
                            .fill(Color.forestCanopy.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Text(name.prefix(1).uppercased())
                                    .font(.title.bold())
                                    .foregroundStyle(Color.forestCanopy)
                            }
                        
                        Button("Change Photo") {
                            // Photo picker
                        }
                        .font(.caption)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
            Section("Personal Information") {
                TextField("Full Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(isSaving)
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        // Save profile logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
