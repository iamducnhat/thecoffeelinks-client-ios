//
//  LoginView.swift
//  thecoffeelinks-native-swift
//
//  Redesigned Phone Login / OTP Bootstrap
//  Contextual, Trustworthy, and Fluid
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isInputActive: Bool = false
    
    // Default to true to maintain backward compatibility
    var isPresentedModally: Bool = true
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            // Header Content
            VStack(spacing: 0) {
                // Nav/Close Bar
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // Title Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(authViewModel.authState == .otpSent ? "Check your texts" : "What's your number?")
                                .font(AppFont.displayTitle)
                                .foregroundStyle(Color.textInk)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(authViewModel.authState == .otpSent ? "We sent a code to \(authViewModel.phoneNumber)" : "We'll text you a code to verify your account.")
                                .font(AppFont.body)
                                .foregroundStyle(Color.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 20)
                        
                        // Input Section
                        VStack(spacing: 24) {
                            if authViewModel.authState != .otpSent {
                                phoneInputSection
                                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading).combined(with: .opacity)))
                            } else {
                                otpInputSection
                                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing).combined(with: .opacity)))
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
            if !authViewModel.isAuthenticated {
                authViewModel.authState = .idle
                authViewModel.phoneNumber = ""
                authViewModel.otpCode = ""
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authViewModel.authState)
        .alert(isPresented: Binding<Bool>(
            get: { authViewModel.authState == .error },
            set: { show in if !show { authViewModel.authState = .idle } }
        )) {
            Alert(
                title: Text("Something went wrong"),
                message: Text(authViewModel.error ?? "Please try again."),
                dismissButton: .default(Text("OK")) {
                    authViewModel.error = nil
                    // Stay on current state to allow retry
                     if authViewModel.otpCode.isEmpty {
                        authViewModel.authState = .idle
                    } else {
                        // If failed on OTP verify, stay on OTP
                         authViewModel.authState = .otpSent
                    }
                }
            )
        }
    }
    
    // MARK: - Phone Input
    
    private var phoneInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Input Field
            HStack(spacing: 12) {
                Text("🇻🇳 +84")
                    .font(AppFont.monoBody)
                    .foregroundStyle(Color.textInk)
                    .padding(.leading, 16)
                
                TextField("912 345 678", text: $authViewModel.phoneNumber)
                    .textFieldStyle(.plain)
                    .font(AppFont.monoHeadline) // Larger for input
                    .foregroundStyle(Color.textInk)
                    .keyboardType(.numberPad)
                    .padding(.vertical, 16)
            }
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isInputActive ? Color.primaryEspresso : Color.border, lineWidth: 1.5)
            )
            .onTapGesture { isInputActive = true }
             
             // CTA
            Button {
                let digits = authViewModel.phoneNumber.filter { $0.isNumber }
                authViewModel.sendOTP(phoneNumber: digits)
            } label: {
                ZStack {
                    if authViewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Continue")
                            .font(AppFont.monoCTA)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isValidPhone ? Color.primaryEspresso : Color.border) // Active/Disabled colors
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!isValidPhone || authViewModel.isLoading)
            .animation(.easeInOut(duration: 0.2), value: isValidPhone)
            
            // Security Note
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                Text("Your info is securely handled.")
                    .font(AppFont.uiCaption)
            }
            .foregroundStyle(Color.textMuted)
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    var isValidPhone: Bool {
        authViewModel.phoneNumber.filter { $0.isNumber }.count >= 9
    }
    
    // MARK: - OTP Input
    
    private var otpInputSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // OTP Field
            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .foregroundStyle(Color.primaryEspresso)
                    .padding(.leading, 16)
                
                TextField("000000", text: $authViewModel.otpCode)
                    .textFieldStyle(.plain)
                    .font(AppFont.monoHeadline)
                    .foregroundStyle(Color.textInk)
                    .keyboardType(.numberPad)
                    .padding(.vertical, 16)
                    .onChange(of: authViewModel.otpCode) { newValue in
                        if newValue.count == 6 {
                            authViewModel.verifyOTP(code: newValue)
                        }
                    }
            }
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primaryEspresso, lineWidth: 1.5)
            )
            
            if authViewModel.isLoading {
                HStack {
                    ProgressView().tint(Color.primaryEspresso)
                    Text("Verifying...")
                         .font(AppFont.body)
                         .foregroundStyle(Color.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // Resend / Edit
            HStack {
                Button("Wrong number?") {
                    authViewModel.authState = .idle
                    authViewModel.otpCode = ""
                }
                .font(AppFont.uiCaption)
                .foregroundStyle(Color.textMuted)
                
                Spacer()
                
                Button("Resend Code") {
                    let digits = authViewModel.phoneNumber.filter { $0.isNumber }
                    authViewModel.sendOTP(phoneNumber: digits)
                }
                .font(AppFont.uiCaption)
                .foregroundStyle(Color.primaryEspresso)
            }
            
            #if DEBUG
            Button {
                let digits = authViewModel.phoneNumber.filter { $0.isNumber }
                authViewModel.bypassOTP(phoneNumber: digits)
            } label: {
                    Text("Dev: Skip (Bypass)")
                    .font(AppFont.uiCaption)
                    .foregroundStyle(Color.semanticError)
                    .padding(.top, 20)
            }
            #endif
        }
    }
}
