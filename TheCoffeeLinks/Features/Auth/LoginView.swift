//
//  LoginView.swift
//  thecoffeelinks-client-ios
//
//  Redesigned Auth Flow: Sign In / Sign Up
//  Supports Phone+Password, Sign Up with Profile, and Legacy OTP
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @Namespace private var tabNamespace
    
    // Tab State
    enum AuthTab {
        case signIn
        case signUp
    }
    @State private var selectedTab: AuthTab = .signIn
    
    // Default to true to maintain backward compatibility
    var isPresentedModally: Bool = true
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            // Main Content
            VStack(spacing: 0) {
                // Nav Bar
                navBar
                
                ScrollView {
                     VStack(alignment: .leading, spacing: 24) {
                         
                         // Header & Tab Switcher
                         if authViewModel.authState != .otpSent {
                             headerSection
                             tabSwitcher
                         } else {
                             // OTP Header
                             VStack(spacing: 8) {
                                  Text("login_verify_title")
                                     .font(AppFont.displayTitle)
                                     .foregroundStyle(Color.textInk)
                                     .multilineTextAlignment(.center)
                                  
                                  Text(String(localized: "login_message_otp_sent \(authViewModel.phoneNumber)"))
                                     .font(AppFont.body)
                                     .foregroundStyle(Color.textMuted)
                                     .multilineTextAlignment(.center)
                                     .padding(.horizontal, 32)
                             }
                             .frame(maxWidth: .infinity)
                             .padding(.vertical, 20)
                         }
                         
                         // Forms
                         VStack(spacing: 24) {
                             if authViewModel.authState == .otpSent {
                                 otpInputSection
                                     .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing).combined(with: .opacity)))
                             } else {
                                 if selectedTab == .signIn {
                                     signInForm
                                         .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading).combined(with: .opacity)))
                                 } else {
                                     signUpForm
                                         .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing).combined(with: .opacity)))
                                 }
                             }
                         }
                         
                         Spacer(minLength: 40)
                     }
                     .padding(.horizontal, AppLayout.spacing)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .onDisappear {
            // Reset state on close if needed
             if !authViewModel.isAuthenticated {
                // Optional: reset fields
             }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: authViewModel.authState)
        .alert(isPresented: Binding<Bool>(
            get: { authViewModel.authState == .error },
            set: { show in if !show { authViewModel.authState = .idle } }
        )) {
            Alert(
                title: Text("error_dialog_title"),
                message: Text(authViewModel.error ?? "Please try again."),
                dismissButton: .default(Text("btn_ok")) {
                    authViewModel.error = nil // Clear error
                    // If on OTP, stay to allow retry?
                    if !authViewModel.otpCode.isEmpty {
                         authViewModel.authState = .otpSent
                    } else {
                        // Return to form
                        authViewModel.authState = .idle
                    }
                }
            )
        }
    }
    
    // MARK: - Components
    
    private var navBar: some View {
        Group {
            if isPresentedModally {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textMuted)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, AppLayout.spacing)
                .padding(.top, AppLayout.spacing)
            } else {
                Spacer().frame(height: 60)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(selectedTab == .signIn ? "login_tab_signin" : "login_tab_signup")
                .font(AppFont.displayTitle)
                .foregroundStyle(Color.textInk)
                .multilineTextAlignment(.center)
                .id("Title-\(selectedTab)")
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            
            Text(selectedTab == .signIn ? "login_subtitle_signin" : "login_subtitle_signup")
                .font(AppFont.body)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity) // Center horizontally
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            tabButton(title: "login_tab_signin", tab: .signIn)
            tabButton(title: "login_tab_signup", tab: .signUp)
        }
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        .padding(.vertical, 8)
    }
    
    private func tabButton(title: LocalizedStringKey, tab: AuthTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            ZStack {
                if selectedTab == tab {
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius - 4, style: AppLayout.cornerStyle)
                        .fill(Color.primaryEspresso)
                        .matchedGeometryEffect(id: "TabBackground", in: tabNamespace) // Simplify, just color fill for now
                        .padding(4)
                }
                
                Text(title)
                    .font(AppFont.headline) // Slightly bolder for tab
                    .foregroundStyle(selectedTab == tab ? Color.backgroundPaper : Color.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
    }
    
    // MARK: - Forms
    
    private var signInForm: some View {
        VStack(spacing: 20) {
            AuthTextField(
                icon: "phone",
                placeholder: "912 345 678",
                text: $authViewModel.phoneNumber,
                keyboardType: UIKeyboardType.numberPad,
                prefix: "+84"
            )
            
            AuthTextField(
                icon: "lock",
                placeholder: "password_placeholder",
                text: $authViewModel.password,
                isSecure: true
            )
            
            // Login Action
            Button {
                authViewModel.loginWithPassword()
            } label: {
                PrimaryButtonLabel(
                    text: "btn_signin",
                    isLoading: authViewModel.isLoading
                )
            }
            .disabled(!canSignIn || authViewModel.isLoading)
            .opacity(canSignIn ? 1 : 0.6)
            
            // Legacy / Alternative
            Divider().padding(.vertical, 8)
            
            Button("login_use_otp_instead") {
                // Switch to OTP flow (send OTP first)
                let digits = authViewModel.phoneNumber.filter { $0.isNumber }
                if digits.count >= 9 {
                    authViewModel.sendOTP(phoneNumber: digits)
                }
            }
            .font(AppFont.uiCaption)
            .foregroundStyle(Color.primaryEspresso)
        }
    }
    
    private var signUpForm: some View {
        VStack(spacing: 20) {
            AuthTextField(
                icon: "user",
                placeholder: "signup_fullname_placeholder",
                text: $authViewModel.fullName
            )
            
             AuthTextField(
                icon: "calendar",
                placeholder: "DD/MM/YYYY",
                text: $authViewModel.dob,
                keyboardType: .numbersAndPunctuation
            )
            
            AuthTextField(
                icon: "phone",
                placeholder: "912 345 678",
                text: $authViewModel.phoneNumber,
                keyboardType: UIKeyboardType.numberPad,
                prefix: "+84"
            )
            
            AuthTextField(
                icon: "lock",
                placeholder: "password_create_placeholder",
                text: $authViewModel.password,
                isSecure: true
            )
            
            // Terms (Mock)
            HStack(alignment: .top) {
                Image(systemName: "checkmark.square.fill")
                    .foregroundStyle(Color.primaryEspresso)
                Text("signup_terms_agreement")
                    .font(AppFont.uiCaption)
                    .foregroundStyle(Color.textMuted)
            }
            
            Button {
                authViewModel.register()
            } label: {
                PrimaryButtonLabel(
                    text: "btn_create_account",
                    isLoading: authViewModel.isLoading
                )
            }
            .disabled(!canSignUp || authViewModel.isLoading)
            .opacity(canSignUp ? 1 : 0.6)
        }
    }
    
    private var otpInputSection: some View {
        VStack(spacing: 32) {
            
            // Centered Wrapper for Input
            AuthTextField(
                icon: "key",
                placeholder: "000000",
                text: $authViewModel.otpCode,
                keyboardType: UIKeyboardType.numberPad
            )
            .onChange(of: authViewModel.otpCode) { newValue in
                if newValue.count == 6 {
                    authViewModel.verifyOTP(code: newValue)
                }
            }
            
            if authViewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView().tint(Color.primaryEspresso)
                    Text("status_verifying")
                         .font(AppFont.body)
                         .foregroundStyle(Color.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            HStack {
                Button("btn_wrong_number") {
                    authViewModel.authState = .idle
                    authViewModel.otpCode = ""
                }
                .font(AppFont.uiCaption)
                .foregroundStyle(Color.textMuted)
                
                Spacer()
                
                Button("btn_resend_code") {
                    let digits = authViewModel.phoneNumber.filter { $0.isNumber }
                    authViewModel.sendOTP(phoneNumber: digits)
                }
                .font(AppFont.uiCaption)
                .foregroundStyle(Color.primaryEspresso)
            }
            .padding(.horizontal, 4) // Align with input curvature
        }
    }
    
    // MARK: - Validation
    
    var canSignIn: Bool {
        authViewModel.phoneNumber.count >= 9 && !authViewModel.password.isEmpty
    }
    
    var canSignUp: Bool {
        authViewModel.phoneNumber.count >= 9 &&
        !authViewModel.password.isEmpty &&
        authViewModel.password.count >= 6 &&
        !authViewModel.fullName.isEmpty // && Checkbox in real app
    }
}

// MARK: - Helper Views

struct AuthTextField: View {
    var icon: String
    var placeholder: LocalizedStringKey
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var prefix: String? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: AppLayout.spacing) {
            Image(icon)
                .font(.system(size: 20))
                .foregroundStyle(isFocused ? Color.primaryEspresso : Color.textMuted)
                .frame(width: 24)
            
            if let prefix = prefix {
                Text(prefix)
                    .font(AppFont.monoBody)
                    .foregroundStyle(Color.textInk)
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .font(AppFont.body) // Was monoHeadline, but body is more consistent with forms
            .foregroundStyle(Color.textInk)
            .keyboardType(keyboardType)
            .focused($isFocused)
            .padding(.vertical, 12) // Consistent vertical padding
        }
        .padding(.horizontal, AppLayout.spacing) // Inner padding
        .background(Color.surfaceCard) // Use surfaceCard
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(isFocused ? Color.primaryEspresso : Color.border, lineWidth: 1)
        )
    }
}

struct PrimaryButtonLabel: View {
    let text: LocalizedStringKey
    let isLoading: Bool
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView().tint(Color.backgroundPaper)
            } else {
                Text(text)
                    .font(AppFont.monoCTA) // Consistent font
                    .foregroundStyle(Color.backgroundPaper) // Text color on primaryEspresso
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.primaryEspresso)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        .shadow(color: Color.primaryEspresso.opacity(0.15), radius: 8, x: 0, y: 4) // Subtle shadow for depth
    }
}

