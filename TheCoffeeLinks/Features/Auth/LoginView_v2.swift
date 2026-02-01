import SwiftUI

/// Refactored LoginView - Design System v2
/// Capsule-based, Apple-native, Dark mode optimized
struct LoginView_v2: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab = 0
    var isPresentedModally: Bool = true
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                if isPresentedModally {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.top, AppSpacing.screenPadding)
                }
                
                ScrollView {
                    VStack(spacing: AppSpacing.sectionGap) {
                        // Header
                        if authViewModel.authState != .otpSent {
                            VStack(spacing: AppSpacing.md) {
                                Text(selectedTab == 0 ? "Sign In" : "Sign Up")
                                    .font(AppTypography.displayLarge)
                                    .foregroundStyle(Color.textPrimary)
                                
                                Text(selectedTab == 0 ? "Welcome back" : "Create your account")
                                    .font(AppTypography.bodyLarge)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(.top, AppSpacing.xl)
                            
                            // Tab switcher
                            CapsuleSegmentedPicker(
                                selection: $selectedTab,
                                options: [
                                    (0, "Sign In"),
                                    (1, "Sign Up")
                                ]
                            )
                            .padding(.horizontal, AppSpacing.screenPadding)
                        } else {
                            // OTP Header
                            VStack(spacing: AppSpacing.md) {
                                Text("Verify Phone")
                                    .font(AppTypography.displayLarge)
                                    .foregroundStyle(Color.textPrimary)
                                
                                Text("Code sent to \(authViewModel.phoneNumber)")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundStyle(Color.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, AppSpacing.xl)
                            .padding(.horizontal, AppSpacing.xl)
                        }
                        
                        // Forms
                        VStack(spacing: AppSpacing.xl) {
                            if authViewModel.authState == .otpSent {
                                otpForm
                            } else {
                                if selectedTab == 0 {
                                    signInForm
                                } else {
                                    signUpForm
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { authViewModel.authState == .error },
            set: { show in if !show { authViewModel.authState = .idle } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(authViewModel.error ?? "Please try again."),
                dismissButton: .default(Text("OK")) {
                    authViewModel.error = nil
                    authViewModel.authState = authViewModel.otpCode.isEmpty ? .idle : .otpSent
                }
            )
        }
    }
    
    // MARK: - Sign In Form
    
    private var signInForm: some View {
        VStack(spacing: AppSpacing.lg) {
            CapsuleTextField(
                placeholder: "912 345 678",
                text: $authViewModel.phoneNumber,
                icon: "phone",
                prefix: "+84",
                keyboardType: .numberPad
            )
            
            CapsuleTextField(
                placeholder: "Password",
                text: $authViewModel.password,
                icon: "lock",
                isSecure: true
            )
            
            CapsuleButton("Sign In", style: .primary, isLoading: authViewModel.isLoading) {
                authViewModel.loginWithPassword()
            }
            .padding(.top, AppSpacing.sm)
            
            CapsuleButton("Sign in with OTP", style: .ghost) {
                authViewModel.sendOTP(phoneNumber: authViewModel.phoneNumber)
            }
        }
    }
    
    // MARK: - Sign Up Form
    
    private var signUpForm: some View {
        VStack(spacing: AppSpacing.lg) {
            CapsuleTextField(
                placeholder: "Full Name",
                text: $authViewModel.fullName,
                icon: "person"
            )
            
            CapsuleTextField(
                placeholder: "912 345 678",
                text: $authViewModel.phoneNumber,
                icon: "phone",
                prefix: "+84",
                keyboardType: .numberPad
            )
            
            CapsuleTextField(
                placeholder: "Password",
                text: $authViewModel.password,
                icon: "lock",
                isSecure: true
            )
            
            CapsuleButton("Create Account", style: .primary, isLoading: authViewModel.isLoading) {
                authViewModel.register()
            }
            .padding(.top, AppSpacing.sm)
        }
    }
    
    // MARK: - OTP Form
    
    private var otpForm: some View {
        VStack(spacing: AppSpacing.lg) {
            CapsuleTextField(
                placeholder: "6-digit code",
                text: $authViewModel.otpCode,
                icon: "number",
                keyboardType: .numberPad
            )
            
            CapsuleButton("Verify & Sign In", style: .primary, isLoading: authViewModel.isLoading) {
                authViewModel.verifyOTP(code: authViewModel.otpCode)
            }
            .padding(.top, AppSpacing.sm)
            
            CapsuleButton("Resend Code", style: .ghost) {
                authViewModel.sendOTP(phoneNumber: authViewModel.phoneNumber)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView_v2()
        .environmentObject(DependencyContainer.shared.makeAuthViewModel())
}
