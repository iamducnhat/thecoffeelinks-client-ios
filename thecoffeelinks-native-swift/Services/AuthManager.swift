import Foundation
import Combine
import SwiftUI

@MainActor
class AuthManager: ObservableObject, AuthDelegate {
    static let shared = AuthManager()
    
    // MARK: - Published State
    @Published var isAuthenticated: Bool = false
    @Published var session: UserSession?
    
    // MARK: - Private Props
    private let sessionStore = SessionStore()
    private let apiClient = APIClient.shared
    
    // Track refresh task to prevent multiple parallel refreshes
    private var refreshTask: Task<String, Error>?
    
    private init() {
        // Load session synchronously to prevent UI flash
        if let loadedSession = sessionStore.load() {
            self.session = loadedSession
            self.isAuthenticated = true
            
            // Configure networking in background
            Task {
                await apiClient.setAuthToken(loadedSession.accessToken)
                await apiClient.setAuthDelegate(self)
                
                // Opportunistic refresh
                if loadedSession.willExpire() {
                     try? await self.refreshToken()
                }
            }
        }
    }
    
    // Legacy helper if needed, but init handles startup now
    func restoreSession() async {
        // Re-check just in case, or use for manual refresh?
        // Actually init covers startup. This might be used if we wipe state and want to reload?
        if let loadedSession = sessionStore.load() {
             self.session = loadedSession
             self.isAuthenticated = true
             await apiClient.setAuthToken(loadedSession.accessToken)
             await apiClient.setAuthDelegate(self)
        } else {
             await signOut()
        }
    }
    
    // MARK: - Actions
    
    func login(response: LoginAPIResponse) async {
        guard let token = response.session?.accessToken ?? response.token,
              let refreshToken = response.session?.refreshToken,
              let user = response.user ?? response.session?.user else {
             return
        }
        
        let expiresIn = response.session?.expiresIn ?? 3600 // Default 1 hr if missing
        let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        
        let newSession = UserSession(
            accessToken: token,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            userId: user.id
        )
        
        // Persist
        sessionStore.save(newSession)
        
        // Update State
        self.session = newSession
        self.isAuthenticated = true
        
        // Configure API
        await apiClient.setAuthToken(token)
        await apiClient.setAuthDelegate(self)
    }
    
    func signOut() async {
        // 1. Call API to invalidate session (Backend)
        do {
             // We construct a simple request manually or use APIClient (careful of recursion)
            // Ideally fire and forget
        } catch {
            print("Logout API failed: \(error)")
        }
        
        // 2. Clear Persistence
        sessionStore.clear()
        
        // 3. Reset State
        self.session = nil
        self.isAuthenticated = false
        
        // 4. Clear API Client
        await apiClient.setAuthToken(nil)
    }
    
    // MARK: - AuthDelegate / Refresh Logic
    
    func refreshToken() async throws -> String {
        // If already refreshing, join that task
        if let existingTask = refreshTask {
            return try await existingTask.value
        }
        
        // Start new refresh task
        let task = Task { () -> String in
            defer { self.refreshTask = nil }
            
            guard let currentSession = session else {
                throw APIClient.APIError.unauthorized(nil)
            }
            
            // Let's assume standard custom endpoint for now.
            // We use APIClient's specific refresh method to avoid recursion
            let newSession: LoginAPIResponse = try await APIClient.shared.performTokenRefresh(refreshToken: currentSession.refreshToken)
            
            guard let newToken = newSession.session?.accessToken ?? newSession.token,
                  let newRefreshToken = newSession.session?.refreshToken,
                  let user = newSession.user ?? newSession.session?.user else {
                throw APIClient.APIError.unauthorized(nil)
            }
             
             // Update Session
             let expiresIn = newSession.session?.expiresIn ?? 3600
             let validUntil = Date().addingTimeInterval(TimeInterval(expiresIn))
            
             let updatedSession = UserSession(
                 accessToken: newToken,
                 refreshToken: newRefreshToken,
                 expiresAt: validUntil,
                 userId: currentSession.userId
             )
             
             sessionStore.save(updatedSession)
             self.session = updatedSession
             await apiClient.setAuthToken(newToken)
             
             return newToken
        }
        
        self.refreshTask = task
        return try await task.value
    }
}
