//
//  EditProfileView.swift
//  thecoffeelinks-client-ios
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
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: AppSpacing.lg) {
                    HStack {
                        Button(String(localized: "common_cancel")) {
                            dismiss()
                        }
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                        
                        Text(String(localized: "profile_edit_title"))
                            .font(AppTypography.displayMedium)
                            .foregroundStyle(Color.textPrimary)
                            .fixedSize()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        
                        Button(String(localized: "common_save")) {
                            saveProfile()
                        }
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(Color.accentPrimary)
                        .disabled(name.isEmpty || authViewModel.isLoading)
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    Divider()
                        .background(Color.borderSecondary)
                        .padding(.horizontal, -AppSpacing.screenPadding)
                }
                .background(Color.bgPrimary)
                
                ScrollView {
                    VStack(spacing: AppLayout.spacingXL) {
                        // Section 1: Basic Info
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text(String(localized: "profile_public_label"))
                                .font(AppFont.uiCaption)
                                .foregroundStyle(Color.textSecondary)
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
