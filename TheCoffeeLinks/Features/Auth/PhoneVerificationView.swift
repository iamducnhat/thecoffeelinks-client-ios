import SwiftUI
import Combine

struct PhoneVerificationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var cooldownSeconds = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text("Verify Phone Number")
                        .font(BaseViewFont.displayTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("We sent a 6-digit code to your phone number.\nPlease enter it to continue.")
                        .font(BaseViewFont.body)
                        .foregroundStyle(BaseViewColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    if let phone = authViewModel.currentUser?.phone {
                        Text(phone)
                            .font(BaseViewFont.monoBody)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .padding(.top, 4)
                    }
                }
                .padding(.top, 60)
                
                // OTP Input
                VStack(spacing: 32) {
                    AppTextInput(
                                        title: nil,
                                        text: $authViewModel.otpCode,
                                        placeholder: "000000",
                                        leadingIcon: "number",
                        keyboardType: .numberPad
                    )
                    .onChange(of: authViewModel.otpCode) { newValue in
                        if newValue.count == 6 {
                            authViewModel.verifyOTP(code: newValue)
                        }
                    }
                    
                    if authViewModel.isLoading {
                        HStack(spacing: 8) {
                            ProgressView().tint(BaseViewColor.accent)
                            Text("Verifying...")
                                .font(BaseViewFont.body)
                                .foregroundStyle(BaseViewColor.textSecondary)
                        }
                    }
                    
                    // Error Message
                    if let error = authViewModel.error {
                        Text(error)
                            .font(BaseViewFont.uiCaption)
                            .foregroundStyle(BaseViewColor.semanticError)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Actions
                    HStack {
                        Button {
                            authViewModel.logout()
                        } label: {
                            Text("Log Out")
                                .font(BaseViewFont.uiCaption)
                                .foregroundStyle(BaseViewColor.textSecondary)
                                .underline()
                        }
                        
                        Spacer()
                        
                        Button {
                            resendCode()
                        } label: {
                            if cooldownSeconds > 0 {
                                Text("Resend in \(cooldownSeconds)s")
                                    .font(BaseViewFont.uiCaption)
                                    .foregroundStyle(BaseViewColor.textSecondary)
                            } else {
                                Text("Resend Code")
                                    .font(BaseViewFont.uiCaption)
                                    .foregroundStyle(BaseViewColor.accent)
                            }
                        }
                        .disabled(cooldownSeconds > 0)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, BaseViewLayout.spacing)
                
                Spacer()
            }
        }
        .onAppear {
            initializeView()
        }
        .onReceive(timer) { _ in
            if cooldownSeconds > 0 {
                cooldownSeconds -= 1
            }
        }
    }
    
    private func initializeView() {
        // Ensure phoneNumber is set for Resend logic
        if authViewModel.phoneNumber.isEmpty {
            authViewModel.phoneNumber = authViewModel.currentUser?.phone ?? ""
        }
        // Start cooldown on appear if needed, or just 0
        // Maybe auto-send if we just registered? 
        // For now, assume code was sent on Login/Register.
    }
    
    private func resendCode() {
        guard let phone = authViewModel.currentUser?.phone ?? Optional(authViewModel.phoneNumber), !phone.isEmpty else { return }
        
        let digits = phone.filter { $0.isNumber }
        authViewModel.sendOTP(phoneNumber: digits)
        
        // Start Cooldown
        cooldownSeconds = 30
    }
}
