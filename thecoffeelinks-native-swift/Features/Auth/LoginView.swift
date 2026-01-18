//
//  LoginView.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var scrollOffset = CGFloat.zero
    
    // Default to true to maintain backward compatibility with existing usages
    var isPresentedModally: Bool = true
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            // Fixed Close Button (Only show if modal)
            if isPresentedModally {
                HStack {
                    Spacer()
                    Button {
                        authViewModel.authState = .idle
                        authViewModel.phoneNumber = ""
                        authViewModel.otpCode = ""
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textInk)
                            .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                    }
                }
                .padding(.horizontal, AppLayout.spacing)
                .padding(.top, AppLayout.spacing)
            }
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: AppLayout.spacingXL) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(authViewModel.authState == .otpSent ? "Verify your number" : "Welcome")
                                .font(AppFont.displayTitle)
                                .foregroundColor(Color.textInk)
                            
                            Text(authViewModel.authState == .otpSent ? "We sent a code to your phone" : "Sign in to continue")
                                .font(AppFont.body)
                                .foregroundColor(Color.textMuted)
                        }
                        .padding(.top, 80)
                        
                        Color.secondary.frame(height: 1)
                        
                        if authViewModel.authState != .otpSent {
                            phoneInputSection
                        } else {
                            otpInputSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppLayout.spacing)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
            }
        }
        .onDisappear {
            if !authViewModel.isAuthenticated {
                authViewModel.authState = .idle
                authViewModel.phoneNumber = ""
                authViewModel.otpCode = ""
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { authViewModel.authState == .error },
            set: { show in if !show { authViewModel.authState = .idle } }
        )) {
            Alert(
                title: Text("Oops!"),
                message: Text(authViewModel.error ?? "Something went wrong. Please try again."),
                dismissButton: .default(Text("OK")) {
                    authViewModel.error = nil
                    authViewModel.authState = .idle
                }
            )
        }
    }
    
    // MARK: - Phone Input Section
    
    private var phoneInputSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            Text("Phone Number")
                .textCase(.uppercase)
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
            
            HStack(spacing: AppLayout.spacingMedium) {
                Image(systemName: "phone")
                    .font(AppFont.body)
                    .foregroundStyle(Color.textMuted)
                
                TextField("0912345678", text: $authViewModel.phoneNumber)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AppFont.monoBody)
                    .keyboardType(.phonePad)
                    .foregroundStyle(Color.textInk)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .overlay {
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
            }
            
            Button {
                let digits = authViewModel.phoneNumber.filter { $0.isNumber }
                authViewModel.sendOTP(phoneNumber: digits)
            } label: {
                Text("Send code")
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.backgroundPaper)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
            .disabled(authViewModel.phoneNumber.filter { $0.isNumber }.count < 10)
            .opacity(authViewModel.phoneNumber.filter { $0.isNumber }.count < 10 ? 0.666 : 1.0)
            
            if authViewModel.isLoading {
                HStack {
                    ProgressView().tint(Color.primaryEspresso)
                    Text("Sending...")
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.textMuted)
                }
            }
        }
    }
    
    // MARK: - OTP Input Section
    
    private var otpInputSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            Text("Verification Code")
                .textCase(.uppercase)
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
            
            HStack(spacing: AppLayout.spacingMedium) {
                Image(systemName: "lock.shield")
                    .font(AppFont.body)
                    .foregroundStyle(Color.textMuted)
                
                TextField("6-digit code", text: $authViewModel.otpCode)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AppFont.monoBody)
                    .keyboardType(.numberPad)
                    .foregroundStyle(Color.textInk)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .overlay {
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
            }
            
            Button {
                authViewModel.verifyOTP(code: authViewModel.otpCode)
            } label: {
                Text("Verify")
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.backgroundPaper)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
            .disabled(authViewModel.otpCode.count != 6)
            .opacity(authViewModel.otpCode.count != 6 ? 0.666 : 1.0)
            
            // Secondary Actions
            VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
                Button {
                    authViewModel.authState = .idle
                    authViewModel.otpCode = ""
                } label: {
                    Text("Use a different number")
                        .font(AppFont.uiCaption)
                        .foregroundColor(Color.primaryEspresso)
                }
                
                #if DEBUG
                Button {
                    let digits = authViewModel.phoneNumber.filter { $0.isNumber }
                    authViewModel.bypassOTP(phoneNumber: digits)
                } label: {
                    Text("Dev: Skip verification")
                        .font(AppFont.uiCaption)
                        .foregroundColor(Color.semanticError)
                }
                #endif
            }
            .padding(.top, AppLayout.spacingMedium)
        }
    }
}
