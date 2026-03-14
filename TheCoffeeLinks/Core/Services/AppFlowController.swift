//
//  AppFlowController.swift
//  TheCoffeeLinks
//
//  Centralized app flow state machine
//  Prevents race conditions by loading state synchronously before UI renders
//

import Foundation
import Combine
import SwiftUI
// Note: This file needs to be added to the TheCoffeeLinks target in Xcode
/// Represents all possible states in the app lifecycle
enum AppFlowState: Equatable {
    case launching                      // Initial state, showing splash
    case checkingAuth                   // Loading tokens and validating session
    case loggedOut                      // No valid session, show login
    case loggingIn                      // Auth in progress
    case pendingPhoneVerification       // Logged in but phone not verified
    case loggedInIncompleteProfile      // Phone verified but profile incomplete
    case onboarding                     // Need to complete onboarding/setup
    case guestReady                     // Guest mode (no auth), can browse menu
    case ready                          // Fully authenticated and ready
    case error(String)                  // Error state with message
    
    var description: String {
        switch self {
        case .launching: return "launching"
        case .checkingAuth: return "checkingAuth"
        case .loggedOut: return "loggedOut"
        case .loggingIn: return "loggingIn"
        case .pendingPhoneVerification: return "pendingPhoneVerification"
        case .loggedInIncompleteProfile: return "loggedInIncompleteProfile"
        case .onboarding: return "onboarding"
        case .guestReady: return "guestReady"
        case .ready: return "ready"
        case .error(let message): return "error(\(message))"
        }
    }
    
    /// Whether this state requires authentication
    var requiresAuth: Bool {
        switch self {
        case .guestReady, .launching, .loggedOut, .loggingIn:
            return false
        default:
            return true
        }
    }
}

@MainActor
class AppFlowController: ObservableObject {
    @Published private(set) var currentState: AppFlowState = .launching
    @Published private(set) var isInitialized: Bool = false
    
    private let keychainManager: KeychainManager
    private let profileStorage: ProfileStorageProtocol
    private let authRepository: AuthRepository
    private var cancellables = Set<AnyCancellable>()
    
    // Cache expiry constants
    private let cacheExpiryInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    private let verificationCacheKey = "isPhoneVerified_cached"
    private let verificationTimestampKey = "isPhoneVerified_timestamp"
    
    // Session refresh guard to avoid duplicate refresh on cold launch
    private let sessionRefreshCooldown: TimeInterval = 5 // seconds
    private var lastSessionRefreshAt: Date?
    
    init(keychainManager: KeychainManager,
         profileStorage: ProfileStorageProtocol,
         authRepository: AuthRepository) {
        self.keychainManager = keychainManager
        self.profileStorage = profileStorage
        self.authRepository = authRepository
    }
    
    /// Synchronously initialize app state - MUST be called before UI renders
    /// This prevents race conditions by checking all state before ContentView loads
    func initializeSync() {
        debugLog("🚀 [AppFlowController] Starting synchronous initialization")
        
        // Step 1: Check for valid access token
        guard let accessToken = keychainManager.getAccessToken(), !accessToken.isEmpty else {
            debugLog("❌ [AppFlowController] No access token found")
            
            // Check if onboarding completed to determine guest vs logged out state
            if !isOnboardingCompleted() {
                currentState = .onboarding
            } else {
                currentState = .guestReady
            }
            
            isInitialized = true
            return
        }
        
        debugLog("✅ [AppFlowController] Access token found")
        
        // Step 2: Check if phone verification cache is valid
        let (isCachedVerified, isCacheValid) = checkCachedVerificationStatus()
        
        if !isCacheValid {
            debugLog("⚠️ [AppFlowController] Verification cache expired or invalid")
            // Cache expired, need to check server
            currentState = .checkingAuth
            isInitialized = true
            return
        }
        
        // Step 3: Load cached user profile
        guard let cachedUser = profileStorage.loadUser() else {
            debugLog("⚠️ [AppFlowController] No cached user profile")
            currentState = .checkingAuth
            isInitialized = true
            return
        }
        
        debugLog("✅ [AppFlowController] Cached user loaded: \(cachedUser.fullName)")
        
        // Step 3.5: Load App Attest key for this user
        let attestService = AppAttestService.shared
        if attestService.isAvailable {
            // Prefer userId for App Attest key identity
            var userId = keychainManager.getUserId()
            if userId == nil || userId?.isEmpty == true {
                userId = cachedUser.id
                keychainManager.saveUserId(cachedUser.id)
                debugLog("✅ [AppFlowController] Saved userId from cached user to keychain")
            }
            
            if let userId = userId, !userId.isEmpty {
                attestService.loadKeyForUser(userId)
                debugLog("✅ [AppFlowController] Loaded App Attest key for cached user: \(userId)")
            } else {
                debugLog("⚠️ [AppFlowController] No userId available for App Attest key loading")
            }
        }
        
        // Step 4: Determine state based on cached data
        if !isCachedVerified {
            debugLog("➡️ [AppFlowController] Phone not verified")
            currentState = .pendingPhoneVerification
        } else if !isOnboardingCompleted() {
            debugLog("➡️ [AppFlowController] Onboarding not completed")
            currentState = .onboarding
        } else {
            debugLog("✅ [AppFlowController] User ready")
            currentState = .ready
        }
        
        isInitialized = true
        debugLog("🎯 [AppFlowController] Initial state: \(currentState.description)")
    }
    
    /// Asynchronously validate auth state with server (called after UI renders)
    func validateAuthState() async {
        debugLog("🔄 [AppFlowController] Validating auth state with server")
        
        let hasRefreshToken = {
            if let token = keychainManager.getRefreshToken(), !token.isEmpty { return true }
            return false
        }()
        
        if (currentState == .guestReady || currentState == .loggedOut), !hasRefreshToken {
            debugLog("⏭️ [AppFlowController] In guest/logged out mode with no refresh token, skipping validation")
            return
        }
        
        // Proactively refresh session on app open to extend refresh token lifetime
        await refreshSessionIfNeeded()
        
        guard let accessToken = keychainManager.getAccessToken(), !accessToken.isEmpty else {
            debugLog("⏭️ [AppFlowController] No access token after refresh attempt, skipping server validation")
            return
        }
        
        let previousState = currentState

        // Update state to checking
        currentState = .checkingAuth
        
        do {
            // Fetch current user from server
            let user = try await authRepository.getCurrentUser()
            debugLog("✅ [AppFlowController] Server validation success")

            // If server says guest, immediately switch to guest mode.
            if user.id == "guest" {
                debugLog("➡️ [AppFlowController] Server returned guest user")
                currentState = .guestReady
                return
            }

            // Update cached data
            profileStorage.saveUser(user)
            
            let isVerified = user.phoneVerificationStatus == .verified
            saveVerificationStatus(isVerified)
            
            // Determine final state
            await determineStateFromUser(user)
            
        } catch {
            debugLog("❌ [AppFlowController] Server validation failed: \(error)")
            
            // Check if token is actually invalid or just network issue
            if isAuthError(error) {
                // Auth error - force logout to guest mode
                currentState = .guestReady
                clearAuthState()
            } else {
                // Network error - fall back to cached state
                debugLog("⚠️ [AppFlowController] Using cached state due to network error")
                currentState = previousState
            }
        }
    }
    
    /// Called on app resume from background
    func handleAppResume() async {
        debugLog("🔄 [AppFlowController] Handling app resume")
        
        // Always attempt a refresh on app open/foreground to extend session
        await refreshSessionIfNeeded()
        
        // If we were in guest mode but now have a token, re-validate
        if currentState == .guestReady {
            if let token = keychainManager.getAccessToken(), !token.isEmpty {
                await validateAuthState()
                return
            }
        }
        
        // Check if verification cache is still valid
        let (_, isCacheValid) = checkCachedVerificationStatus()
        
        if !isCacheValid {
            debugLog("⚠️ [AppFlowController] Cache expired on resume, re-validating")
            await validateAuthState()
        } else if currentState == .ready {
            // Just refresh data in background, don't change state
            debugLog("✅ [AppFlowController] Cache valid, refreshing data in background")
            Task {
                try? await authRepository.getCurrentUser()
            }
        }
    }
    
    /// Transition to logged in state (called after successful login)
    func transitionToLoggedIn(user: User) {
        debugLog("✅ [AppFlowController] Transitioning to logged in")
        
        profileStorage.saveUser(user)
        
        let isVerified = user.phoneVerificationStatus == .verified
        saveVerificationStatus(isVerified)
        
        Task {
            await determineStateFromUser(user)
        }
    }
    
    /// Transition to logged out state
    func transitionToLoggedOut() {
        debugLog("🚪 [AppFlowController] Transitioning to logged out")
        currentState = .guestReady
        clearAuthState()
    }
    
    /// Mark phone as verified and update state
    func markPhoneVerified() {
        debugLog("✅ [AppFlowController] Phone verified")
        saveVerificationStatus(true)
        
        if !isOnboardingCompleted() {
            currentState = .onboarding
        } else {
            currentState = .ready
        }
    }
    
    /// Mark onboarding as completed
    func markOnboardingCompleted() {
        debugLog("✅ [AppFlowController] Onboarding completed")
        UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
        UserDefaults.standard.set(true, forKey: "isInitialSetupCompleted")
        currentState = .ready
    }
    
    // MARK: - Private Helpers
    
    private func determineStateFromUser(_ user: User) async {
        let isVerified = user.phoneVerificationStatus == .verified
        
        if !isVerified {
            currentState = .pendingPhoneVerification
        } else if !isOnboardingCompleted() {
            currentState = .onboarding
        } else {
            currentState = .ready
        }
        
        debugLog("🎯 [AppFlowController] Final state: \(currentState.description)")
    }
    
    private func isOnboardingCompleted() -> Bool {
        let onboardingCompleted = UserDefaults.standard.bool(forKey: "isOnboardingCompleted")
        let setupCompleted = UserDefaults.standard.bool(forKey: "isInitialSetupCompleted")
        return onboardingCompleted && setupCompleted
    }
    
    private func checkCachedVerificationStatus() -> (isVerified: Bool, isValid: Bool) {
        guard let timestamp = UserDefaults.standard.object(forKey: verificationTimestampKey) as? Date else {
            // No timestamp means cache doesn't exist or is very old
            return (false, false)
        }
        
        let age = Date().timeIntervalSince(timestamp)
        let isValid = age < cacheExpiryInterval
        
        let isVerified = UserDefaults.standard.bool(forKey: verificationCacheKey)
        
        debugLog("📦 [AppFlowController] Cached verification: \(isVerified), age: \(Int(age))s, valid: \(isValid)")
        
        return (isVerified, isValid)
    }
    
    private func saveVerificationStatus(_ isVerified: Bool) {
        UserDefaults.standard.set(isVerified, forKey: verificationCacheKey)
        UserDefaults.standard.set(Date(), forKey: verificationTimestampKey)
        debugLog("💾 [AppFlowController] Saved verification status: \(isVerified)")
    }
    
    private func clearAuthState() {
        // Clear App Attest key before clearing phone number
        if let userId = keychainManager.getUserId() {
            AppAttestService.shared.clearKeyForUser(userId)
        } else if let phoneNumber = keychainManager.getPhoneNumber() {
            AppAttestService.shared.clearKeyForUser(phoneNumber)
        }
        
        keychainManager.deleteAccessToken()
        keychainManager.deleteRefreshToken()
        keychainManager.deletePhoneNumber()
        keychainManager.deleteUserId()
        profileStorage.clearUser()
        UserDefaults.standard.removeObject(forKey: verificationCacheKey)
        UserDefaults.standard.removeObject(forKey: verificationTimestampKey)
        debugLog("🗑️ [AppFlowController] Cleared auth state")
    }
    
    private func isAuthError(_ error: Error) -> Bool {
        if case NetworkError.unauthorized = error {
            return true
        }

        if case NetworkError.forbidden = error {
            return true
        }

        // Check if error is 401/403 (unauthorized)
        if error is URLError {
            return false // Network errors, not auth errors
        }
        
        let errorString = error.localizedDescription.lowercased()
        return errorString.contains("unauthorized") ||
               errorString.contains("invalid token") ||
               errorString.contains("expired") ||
               errorString.contains("401") ||
               errorString.contains("403")
    }

    private func refreshSessionIfNeeded() async {
        guard let refreshToken = keychainManager.getRefreshToken(), !refreshToken.isEmpty else {
            return
        }
        
        if let lastRefresh = lastSessionRefreshAt,
           Date().timeIntervalSince(lastRefresh) < sessionRefreshCooldown {
            return
        }
        
        let didRefresh = await authRepository.refreshSessionOnAppOpen()
        if didRefresh {
            lastSessionRefreshAt = Date()
            debugLog("✅ [AppFlowController] Session refreshed on app open")
        }
    }
}
