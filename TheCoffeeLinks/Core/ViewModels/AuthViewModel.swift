import Foundation
import Combine

class AuthViewModel: BaseViewModel {
    private let authRepository: AuthRepository
    private let profileStorage: ProfileStorageProtocol
    
    // Reference to AppFlowController for state synchronization
    // Note: Set via dependency injection after initialization to avoid circular dependency
    weak var appFlowController: AppFlowController? {
        didSet { bindAppFlowController() }
    }
    private var appFlowCancellable: AnyCancellable?

    @Published var currentUser: User? {
        didSet {
            // CRITICAL: Save to ProfileStorage for single source of truth
            if let user = currentUser {
                profileStorage.saveUser(user)
            }
        }
    }
    @Published var isAuthenticated: Bool = false
    @Published var isPhoneVerified: Bool = false // Default false until verified

    // Form fields - Phone Auth
    @Published var phoneNumber: String = ""
    @Published var otpCode: String = ""

    // Form fields - Password / Profile
    @Published var password: String = ""
    @Published var fullName: String = ""
    @Published var dob: String = ""

    // State management
    enum PhoneAuthState {
        case idle
        case otpSent
        case error
    }
    @Published var authState: PhoneAuthState = .idle

    init(authRepository: AuthRepository, profileStorage: ProfileStorageProtocol = ProfileStorage()) {
        self.authRepository = authRepository
        self.profileStorage = profileStorage
        super.init()
        // Auth state is now managed by AppFlowController
        // checkSession() is called by AppFlowController during initialization
        loadCachedSession()
    }

    /// Check session - DEPRECATED, use AppFlowController instead
    /// Kept for backward compatibility with existing views
    func checkSession() {
        // No-op: Auth state is now managed by AppFlowController
        debugLog("⚠️ [AuthViewModel] checkSession() called - this is deprecated, use AppFlowController")
    }

    private func bindAppFlowController() {
        appFlowCancellable = appFlowController?.$currentState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                if state.requiresAuth {
                    self.loadCachedSession()
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
    }
    
    private func loadCachedSession() {
        let hasToken = DependencyContainer.shared.keychainManager.getAccessToken() != nil
        if hasToken, let cachedUser = profileStorage.loadUser() {
            currentUser = cachedUser
            isAuthenticated = true
            isPhoneVerified = cachedUser.phoneVerificationStatus == .verified
        } else if !hasToken {
            isAuthenticated = false
            currentUser = nil
            isPhoneVerified = false
        }
    }
    
    // MARK: - Phone + Password Auth
    
    func register() {
        let formattedNumber = formatPhoneNumber(self.phoneNumber)
        
        // Basic validation
        guard !password.isEmpty, !fullName.isEmpty, !dob.isEmpty else {
            self.error = "Please fill in all fields"
            self.authState = .error
            return
        }
        
        // Format Date: DD/MM/YYYY -> YYYY-MM-DD
        let formattedDob = formatDateForAPI(self.dob)
        
        withLoading {
            do {
                _ = try await self.authRepository.register(
                    phone: formattedNumber,
                    password: self.password,
                    name: self.fullName,
                    dob: formattedDob
                )
                debugLog("✅ Registered. Waiting for OTP.")
                // NOTE: After OTP verification, fetchCurrentUser() will be called
                // in verifyOTP() to get the full profile with the name we just registered
                await MainActor.run {
                    self.authState = .otpSent
                    self.error = nil // Clear error
                }
            } catch {
                debugLog("❌ [AuthViewModel] Register Error: \(error)")
                
                // Clear any stale auth tokens to prevent automatic token refresh
                DependencyContainer.shared.keychainManager.deleteAccessToken()
                DependencyContainer.shared.keychainManager.deleteRefreshToken()
                await DependencyContainer.shared.networkService.clearAuthToken()
                
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.authState = .error
                }
            }
        }
    }
    
    func loginWithPassword() {
        let formattedNumber = formatPhoneNumber(self.phoneNumber)
        
        withLoading {
            do {
                let user = try await self.authRepository.loginWithPassword(phone: formattedNumber, password: self.password)
                
                // Sync Realtime Token
                if let token = DependencyContainer.shared.keychainManager.getAccessToken() {
                    DependencyContainer.shared.realtimeService.setAuthToken(token)
                }
                
                // CRITICAL: Fetch full user profile from /api/user/profile to get actual name
                let fullUser = try await self.fetchCurrentUser()
                
                await MainActor.run {
                    self.isAuthenticated = true
                    self.isPhoneVerified = fullUser.phoneVerificationStatus == .verified
                    self.authState = .idle
                    self.error = nil
                    
                    // Notify AppFlowController of login
                    self.appFlowController?.transitionToLoggedIn(user: fullUser)
                }
            } catch {
                debugLog("❌ [AuthViewModel] Login Password Error: \(error)")
                
                // Clear any stale auth tokens to prevent automatic token refresh
                DependencyContainer.shared.keychainManager.deleteAccessToken()
                DependencyContainer.shared.keychainManager.deleteRefreshToken()
                await DependencyContainer.shared.networkService.clearAuthToken()
                
                await MainActor.run {
                    self.isAuthenticated = false
                    self.error = error.localizedDescription
                    self.authState = .error
                }
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
                debugLog("✅ OTP sent to \(formattedNumber)")
                await MainActor.run {
                    self.authState = .otpSent
                    self.error = nil
                }
            } catch {
                debugLog("❌ [AuthViewModel] sendOTP Error: \(error)")                
                // Clear any stale auth tokens to prevent automatic token refresh
                DependencyContainer.shared.keychainManager.deleteAccessToken()
                DependencyContainer.shared.keychainManager.deleteRefreshToken()
                await DependencyContainer.shared.networkService.clearAuthToken()
                
                await MainActor.run {
                    self.isAuthenticated = false
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
                let user = try await self.authRepository.verifyOTP(otp: code, phoneNumber: formattedNumber)
                
                // Sync Realtime Token
                if let token = DependencyContainer.shared.keychainManager.getAccessToken() {
                    DependencyContainer.shared.realtimeService.setAuthToken(token)
                }
                
                // CRITICAL: Fetch full user profile from /api/user/profile to get actual name
                let fullUser = try await self.fetchCurrentUser()
                
                await MainActor.run {
                    self.isAuthenticated = true
                    self.isPhoneVerified = fullUser.phoneVerificationStatus == .verified
                    self.authState = .idle
                    self.error = nil
                    
                    // Notify AppFlowController
                    if self.isPhoneVerified {
                        self.appFlowController?.markPhoneVerified()
                    } else {
                        self.appFlowController?.transitionToLoggedIn(user: fullUser)
                    }
                }
            } catch {
                debugLog("❌ [AuthViewModel] verifyOTP Error: \(error)")
                
                // Clear any stale auth tokens to prevent automatic token refresh
                DependencyContainer.shared.keychainManager.deleteAccessToken()
                DependencyContainer.shared.keychainManager.deleteRefreshToken()
                await DependencyContainer.shared.networkService.clearAuthToken()
                
                await MainActor.run {
                    self.isAuthenticated = false
                    self.error = error.localizedDescription
                    self.authState = .error
                }
            }
        }
    }
    
    func bypassOTP(phoneNumber: String) {
        #if !DEBUG
        self.error = "Dev bypass is not available"
        return
        #else
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
        #endif
    }
    
    func loginWithLinkedIn() {
        withLoading {
            debugLog("🔗 Starting LinkedIn Login Flow...")
            let linkedInService = LinkedInService()
            do {
                let token = try await linkedInService.login()
                debugLog("✅ LinkedIn Token Received. Logging in to backend for LinkedIn...")
                
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
            
            // CRITICAL: Clear ProfileStorage
            profileStorage.clearUser()
            
            // CRITICAL: Clear Cart on logout
            DependencyContainer.shared.cartStorage.clearCart()
            
            URLCache.shared.removeAllCachedResponses()
            
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
                self.isPhoneVerified = false // Reset
                
                // Notify AppFlowController
                self.appFlowController?.transitionToLoggedOut()
                self.phoneNumber = ""
                self.otpCode = ""
                self.authState = .idle
            }
        }
    }
    
    func fetchCurrentUser() async throws -> User {
        let user = try await authRepository.getCurrentUser()
        await MainActor.run {
            self.currentUser = user  // This will trigger didSet and save to ProfileStorage
            if let bio = user.bio {
                DependencyContainer.shared.userPreferences.userBio = bio
            }
        }
        return user
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
        
        // Remove known prefixes if user typed them manually
        if formatted.hasPrefix("+84") {
            formatted = String(formatted.dropFirst(3))
        } else if formatted.hasPrefix("84") {
            formatted = String(formatted.dropFirst(2))
        }
        
        // Remove leading zero
        if formatted.hasPrefix("0") {
            formatted = String(formatted.dropFirst())
        }
        
        // Always append +84 for this App (Vietnam specific)
        return "+84" + formatted
    }
    
    // Helper to convert DD/MM/YYYY to YYYY-MM-DD
    private func formatDateForAPI(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd/MM/yyyy"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy-MM-dd"
            outputFormatter.locale = Locale(identifier: "en_US_POSIX")
            return outputFormatter.string(from: date)
        }
        
        // Fallback or return original if parsing fails (server will likely reject it, but better than crash)
        return dateString
    }
}
