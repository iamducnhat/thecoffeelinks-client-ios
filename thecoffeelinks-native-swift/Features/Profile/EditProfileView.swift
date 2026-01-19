//
//  EditProfileView.swift
//  thecoffeelinks-native-swift
//
//  Created for Editorial Design System
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Form State
    @State private var name: String = ""
    @State private var bio: String = ""
    
    init() {}
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(AppFont.body)
                    .foregroundStyle(Color.textMuted)
                    
                    Spacer()
                    
                    Text("Edit Profile")
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveProfile()
                    }
                    .font(AppFont.body)
                    .foregroundStyle(Color.primaryEspresso)
                    .disabled(name.isEmpty || authViewModel.isLoading)
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                    .opacity(0.2)
                
                ScrollView {
                    VStack(spacing: AppLayout.spacingXL) {
                        // Section 1: Basic Info
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("PUBLIC PROFILE")
                                .font(AppFont.uiCaption)
                                .foregroundStyle(Color.textMuted)
                                .padding(.horizontal, AppLayout.spacingCompact)
                            
                            AppInput(title: "Name", text: $name, placeholder: "Your name")
                            
                            AppInput(title: "Bio", text: $bio, placeholder: "Tell us about yourself")
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
            
            // Loading Overlay
            if authViewModel.isLoading {
                Color.black.opacity(0.1).ignoresSafeArea()
                ProgressView()
            }
        }
        .onAppear {
            initializeForm()
        }
        .onChange(of: authViewModel.currentUser) { _ in
            // If user updates, we can dismiss? Or just stay.
            // Let's assume on successful save we dismiss.
        }
    }
    
    private func initializeForm() {
        if let user = authViewModel.currentUser {
            name = user.displayName
            bio = user.bio ?? ""
        }
    }
    
    private func saveProfile() {
        authViewModel.updateProfile(name: name, bio: bio)
        dismiss()
    }
}
