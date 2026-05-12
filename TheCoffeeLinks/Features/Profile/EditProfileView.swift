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
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(String(localized: "common_cancel")) {
                        dismiss()
                    }
                    .font(BaseViewFont.labelStrong)
                    .foregroundStyle(BaseViewColor.textSecondary)

                    Spacer()

                    Text(String(localized: "profile_edit_title"))
                        .font(BaseViewFont.sectionTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)

                    Spacer()

                    Button(String(localized: "common_save")) {
                        saveProfile()
                    }
                    .font(BaseViewFont.labelStrong)
                    .foregroundStyle(name.isEmpty || authViewModel.isLoading ? BaseViewColor.textSecondary : BaseViewColor.accent)
                    .disabled(name.isEmpty || authViewModel.isLoading)
                }
                .padding(.horizontal, BaseViewLayout.screenInset)
                .padding(.top, BaseViewLayout.screenTopInset)
                .padding(.bottom, BaseViewLayout.screenInset)

                Rectangle()
                    .fill(BaseViewColor.border)
                    .frame(height: BaseViewLayout.cardBorderWidth)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: BaseViewLayout.majorSectionGap) {
                        VStack(alignment: .leading, spacing: BaseViewLayout.cardGap) {
                            Text(String(localized: "profile_public_label"))
                                .font(BaseViewFont.label)
                                .foregroundStyle(BaseViewColor.textSecondary)
                            
                            AppInput(title: "Name", text: $name, placeholder: "Your name")
                            
                            AppInput(title: "Bio", text: $bio, placeholder: "Tell us about yourself")
                        }
                    }
                    .padding(.horizontal, BaseViewLayout.screenInset)
                    .padding(.top, BaseViewLayout.sectionGap)
                    .padding(.bottom, 100)
                }
            }
            
            if authViewModel.isLoading {
                Color.black.opacity(0.1).ignoresSafeArea()
                ProgressView()
            }
        }
        .onAppear {
            initializeForm()
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
