import Foundation
import Combine
import SwiftUI

enum AuthState {
    case authenticated
    case unauthenticated
    case loading
}

// MARK: - API Response Models

struct AuthResponse: Codable {
    let success: Bool
    let session: AuthSession?
    let user: AuthUser?
    let error: String?
}

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let tokenType: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct AuthUser: Codable {
    let id: String
    let email: String?
    let phone: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, phone
        case createdAt = "created_at"
    }
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

// MARK: - ViewModel

@MainActor
class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    
    @Published var state: AuthState = .loading
    @Published var session: AuthSession?
    @Published var user: AuthUser?
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    private let sessionKey = "auth_session"
    
    init() {
        Task {
            await checkSession()
        }
    }
    
    func checkSession() async {
        // Check for stored session
        if let sessionData = UserDefaults.standard.data(forKey: sessionKey),
           let storedSession = try? JSONDecoder().decode(AuthSession.self, from: sessionData) {
            self.session = storedSession
            await apiClient.setAuthToken(storedSession.accessToken)
            self.state = .authenticated
        } else {
            self.state = .unauthenticated
        }
    }
    
    func signInWithPassword(email: String, password: String) async {
        self.state = .loading
        self.errorMessage = nil
        
        do {
            let loginRequest = LoginRequest(email: email, password: password)
            let response: AuthResponse = try await apiClient.post("/api/auth/login", body: loginRequest)
            
            if response.success, let session = response.session {
                self.session = session
                self.user = response.user
                
                // Store session
                if let sessionData = try? JSONEncoder().encode(session) {
                    UserDefaults.standard.set(sessionData, forKey: sessionKey)
                }
                
                await apiClient.setAuthToken(session.accessToken)
                self.state = .authenticated
            } else {
                self.errorMessage = response.error ?? "Login failed"
                self.state = .unauthenticated
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.state = .unauthenticated
        }
    }
    
    func signOut() async {
        // Call logout API
        do {
            struct EmptyRequest: Encodable {}
            let _: AuthResponse = try await apiClient.post("/api/auth/logout", body: EmptyRequest())
        } catch {
            // Ignore logout errors, still clear local state
        }
        
        // Clear local state
        UserDefaults.standard.removeObject(forKey: sessionKey)
        await apiClient.setAuthToken(nil)
        self.session = nil
        self.user = nil
        self.state = .unauthenticated
    }
}
