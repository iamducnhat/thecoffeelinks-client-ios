import SwiftUI

// MARK: - Auth Mode
enum AuthMode {
    case signIn
    case signUp
}

// MARK: - Login View
struct LoginView: View {
    @ObservedObject var authViewModel = AuthViewModel.shared
    @State private var authMode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Top Section with Logo
                    headerSection(geometry: geometry)
                    
                    // Auth Form Card
                    authFormCard
                        .padding(.horizontal, 24)
                        .padding(.top, -40)
                    
                    Spacer(minLength: 40)
                }
                .frame(minHeight: geometry.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.brandBackground)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private func headerSection(geometry: GeometryProxy) -> some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.coffeeRich, Color.coffeeDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 16) {
                Spacer()
                
                // App Logo/Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.caramel)
                }
                
                // Brand Name
                Text("The Coffee Links")
                    .font(.brandSerif(32))
                    .foregroundStyle(.white)
                
                Text(authMode == .signIn ? "Welcome back" : "Join our community")
                    .font(.brandSans(16))
                    .foregroundStyle(Color.white.opacity(0.8))
                
                Spacer()
                    .frame(height: 60)
            }
            .padding(.top, 60)
        }
        .frame(height: geometry.size.height * 0.38)
        .clipShape(RoundedCornerShape(corners: [.bottomLeft, .bottomRight], radius: 40))
    }
    
    // MARK: - Auth Form Card
    private var authFormCard: some View {
        VStack(spacing: 24) {
            // Mode Switcher
            authModeSwitcher
            
            // Form Fields
            VStack(spacing: 16) {
                if authMode == .signUp {
                    // Full Name Field
                    AuthTextField(
                        placeholder: "Full Name",
                        text: $fullName,
                        icon: "person.fill",
                        keyboardType: .default,
                        textContentType: .name
                    )
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
                }
                
                // Email Field
                AuthTextField(
                    placeholder: "Email Address",
                    text: $email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                
                // Password Field
                AuthSecureField(
                    placeholder: "Password",
                    text: $password,
                    icon: "lock.fill",
                    showPassword: $showPassword
                )
                .focused($focusedField, equals: .password)
                .submitLabel(authMode == .signUp ? .next : .done)
                .onSubmit {
                    if authMode == .signUp {
                        focusedField = .confirmPassword
                    } else {
                        performAuth()
                    }
                }
                
                if authMode == .signUp {
                    // Confirm Password Field
                    AuthSecureField(
                        placeholder: "Confirm Password",
                        text: $confirmPassword,
                        icon: "lock.fill",
                        showPassword: $showPassword
                    )
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.done)
                    .onSubmit { performAuth() }
                }
            }
            
            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.brandSans(14))
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Primary Action Button
            LiquidGlassPrimaryButton(
                authMode == .signIn ? "Sign In" : "Create Account",
                icon: authMode == .signIn ? "arrow.right" : "person.badge.plus",
                isLoading: isLoading,
                isDisabled: !isFormValid,
                tint: .coffeeRich
            ) {
                performAuth()
            }
            
            // Social Login Section
            socialLoginSection 
            
            // Divider
            dividerSection
            
            // Secondary Action
            secondaryActionSection
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Auth Mode Switcher
    private var authModeSwitcher: some View {
        HStack(spacing: 0) {
            ForEach([AuthMode.signIn, AuthMode.signUp], id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        authMode = mode
                        authViewModel.errorMessage = nil
                    }
                } label: {
                    Text(mode == .signIn ? "Sign In" : "Sign Up")
                        .font(.brandSans(15).weight(.semibold))
                        .foregroundStyle(authMode == mode ? Color.white : Color.neutral500)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            authMode == mode
                            ? Color.coffeeRich
                            : Color.clear
                        )
                        .cornerRadius(12)
                }
            }
        }
        .padding(4)
        .background(Color.neutral100)
        .cornerRadius(16)
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.neutral200)
                .frame(height: 1)
            
            Text("or")
                .font(.brandSans(13))
                .foregroundStyle(Color.neutral400)
            
            Rectangle()
                .fill(Color.neutral200)
                .frame(height: 1)
        }
    }
    
    // MARK: - Secondary Action Section
    private var secondaryActionSection: some View {
        VStack(spacing: 16) {
            if authMode == .signIn {
                Button {
                    // Forgot password action
                } label: {
                    Text("Forgot your password?")
                        .font(.brandSans(14))
                        .foregroundStyle(Color.coffeeDark)
                }
            }
            
            HStack(spacing: 4) {
                Text(authMode == .signIn ? "Don't have an account?" : "Already have an account?")
                    .font(.brandSans(14))
                    .foregroundStyle(Color.neutral500)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        authMode = authMode == .signIn ? .signUp : .signIn
                        authViewModel.errorMessage = nil
                    }
                } label: {
                    Text(authMode == .signIn ? "Sign Up" : "Sign In")
                        .font(.brandSans(14).weight(.semibold))
                        .foregroundStyle(Color.coffeeRich)
                }
            }
        }
    }
    
    // MARK: - Social Login Section
    private var socialLoginSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                SocialLoginButton(icon: "apple.logo", label: "Apple")
                SocialLoginButton(icon: "g.circle.fill", label: "Google") 
                // LinkedIn - Blueprint P0
                SocialLoginButton(icon: "l.circle.fill", label: "LinkedIn", color: .blue)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Social Login Component
    struct SocialLoginButton: View {
        let icon: String
        let label: String
        var color: Color = .primary
        
        var body: some View {
            Button {
                // Mock Action
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } label: {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .frame(width: 50, height: 50)
                    .background(Color.neutral100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.neutral200, lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Form Validation
    private var isFormValid: Bool {
        if authMode == .signIn {
            return !email.isEmpty && !password.isEmpty && email.contains("@")
        } else {
            return !email.isEmpty && !password.isEmpty && !fullName.isEmpty &&
                   password == confirmPassword && password.count >= 6 && email.contains("@")
        }
    }
    
    // MARK: - Perform Auth
    private func performAuth() {
        guard isFormValid else { return }
        focusedField = nil
        
        Task {
            isLoading = true
            if authMode == .signIn {
                await authViewModel.signInWithPassword(email: email, password: password)
            } else {
                await authViewModel.signUp(email: email, password: password, name: fullName)
            }
            isLoading = false
        }
    }
}

// MARK: - Auth Text Field
struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.neutral400)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .font(.brandSans(16))
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.neutral50)
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.neutral200, lineWidth: 1)
        }
    }
}

// MARK: - Auth Secure Field
struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.neutral400)
                .frame(width: 24)
            
            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(.brandSans(16))
            .textContentType(.password)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            
            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.neutral400)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.neutral50)
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.neutral200, lineWidth: 1)
        }
    }
}

// MARK: - Rounded Corner Shape
struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview("Login") {
    LoginView()
}

#Preview("Sign Up") {
    LoginView()
}
