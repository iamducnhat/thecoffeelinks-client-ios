import Foundation
import Combine

class AuthViewModel: BaseViewModel {
    private let authRepository: AuthRepository
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    // Form fields - Phone Auth
    @Published var phoneNumber: String = ""
    @Published var otpCode: String = ""
    
    // State management
    enum PhoneAuthState {
        case idle
        case otpSent
        case error
    }
    @Published var authState: PhoneAuthState = .idle
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        super.init()
        checkSession()
    }
    
    func checkSession() {
        if let token = DependencyContainer.shared.keychainManager.getAccessToken() {
            isAuthenticated = true
            // Sync Realtime Token
            DependencyContainer.shared.realtimeService.setAuthToken(token)
            
            Task {
                try? await fetchCurrentUser()
            }
        }
    }
    
    // MARK: - Phone OTP Authentication
    
    func sendOTP(phoneNumber: String) {
        self.phoneNumber = phoneNumber // Cache raw input for UI/verification step
        let formattedNumber = formatPhoneNumber(phoneNumber)
        
        withLoading {
            do {
                try await self.authRepository.sendOTP(phoneNumber: formattedNumber)
                print("✅ OTP sent to \(formattedNumber)")
                await MainActor.run {
                    self.authState = .otpSent
                    self.error = nil
                }
            } catch {
                print("❌ [AuthViewModel] sendOTP Error: \(error)")
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.authState = .error
                }
            }
        }
    }
    
    func verifyOTP(code: String) {
        // Use cached phoneNumber
        guard !phoneNumber.isEmpty else {
            self.error = "Phone number missing"
            return
        }
        
        let formattedNumber = formatPhoneNumber(self.phoneNumber)
        
        withLoading {
            do {
                let user = try await self.authRepository.verifyOTP(code: code, phoneNumber: formattedNumber)
                
                // Sync Realtime Token
                if let token = DependencyContainer.shared.keychainManager.getAccessToken() {
                    DependencyContainer.shared.realtimeService.setAuthToken(token)
                }
                
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.authState = .idle
                    self.error = nil
                }
            } catch {
                print("❌ [AuthViewModel] verifyOTP Error: \(error)")
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.authState = .error
                }
            }
        }
    }
    
    func bypassOTP(phoneNumber: String) {
        let formattedNumber = formatPhoneNumber(phoneNumber)
        withLoading {
            do {
                let user = try await self.authRepository.bypassOTP(phoneNumber: formattedNumber)
                
                // Sync Realtime Token
                if let token = DependencyContainer.shared.keychainManager.getAccessToken() {
                    DependencyContainer.shared.realtimeService.setAuthToken(token)
                }
                
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.authState = .idle
                    self.error = nil
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.authState = .error
                }
            }
        }
    }
    
    func loginWithLinkedIn() {
        withLoading {
            print("🔗 Starting LinkedIn Login Flow...")
            let linkedInService = await LinkedInService()
            do {
                let token = try await linkedInService.login()
                print("✅ LinkedIn Token Received. Logging in to backend for LinkedIn...")
                
                let user = try await self.authRepository.loginWithLinkedIn(code: token)
                
                // Sync Realtime Token
                if let accessToken = DependencyContainer.shared.keychainManager.getAccessToken() {
                    DependencyContainer.shared.realtimeService.setAuthToken(accessToken)
                }
                
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func logout() {
        Task {
            await self.authRepository.logout()
            
            // Clear all caches
            await DependencyContainer.shared.cacheService.clear()
            DependencyContainer.shared.realtimeService.disconnect()
            
            URLCache.shared.removeAllCachedResponses()
            
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
                self.phoneNumber = ""
                self.otpCode = ""
                self.authState = .idle
            }
        }
    }
    
    func fetchCurrentUser() async throws {
        let user = try await authRepository.getCurrentUser()
        await MainActor.run {
            self.currentUser = user
            if let bio = user.bio {
                DependencyContainer.shared.userPreferences.userBio = bio
            }
        }
    }
    
    func updateProfile(name: String, bio: String) {
        withLoading {
            let user = try await self.authRepository.updateProfile(name: name, bio: bio)
             await MainActor.run {
                self.currentUser = user
            }
        }
    }
    private func formatPhoneNumber(_ number: String) -> String {
        var formatted = number.replacingOccurrences(of: " ", with: "")
        // Simple E.164 conversion for VN
        if formatted.hasPrefix("0") {
            formatted = "+84" + formatted.dropFirst()
        }
        return formatted
    }
}

