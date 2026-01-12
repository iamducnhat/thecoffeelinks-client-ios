import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel = AuthViewModel.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningIn = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo or Brand
                Text("The Coffee Links")
                    .font(.brandSerif(40))
                    .foregroundStyle(Color.coffeeDark)
                
                Text("Sign in to continue")
                    .font(.brandSans(16))
                    .foregroundStyle(Color.secondary)
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal)
                
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button {
                    Task {
                        isSigningIn = true
                        await authViewModel.signInWithPassword(email: email, password: password)
                        isSigningIn = false
                    }
                } label: {
                    HStack {
                        if isSigningIn {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                        }
                    }
                    .font(.brandSans(16).bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.coffeeRich)
                    .cornerRadius(12)
                    .shadow(color: Color.coffeeRich.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(isSigningIn || email.isEmpty || password.isEmpty)
                .padding(.horizontal)
                
                Spacer()
                
                // Sign up / Reset password links can go here
                Button("Create an account") {
                    // Navigate to Sign Up
                }
                .font(.brandSans(14))
                .foregroundStyle(Color.coffeeDark)
            }
            .padding()
            .background(Color.brandBackground)
        }
    }
}

#Preview {
    LoginView()
}
