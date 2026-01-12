import Foundation
import Combine
import SwiftUI

enum AuthState: Equatable {
    case authenticated
    case unauthenticated
    case loading
}

// MARK: - API Response Models
// Note: APIClient uses `.convertFromSnakeCase` so property names like `accessToken` 
// will automatically match JSON keys like `access_token`

/// Login response from /api/auth/login
struct LoginAPIResponse: Decodable {
    let success: Bool?
    let session: SupabaseSession?
    let user: SupabaseUser?
    let token: String?
    let error: String?
}

/// Supabase session object
struct SupabaseSession: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let expiresAt: Int?
    let tokenType: String?
    let user: SupabaseUser?
}

/// Supabase user object (from auth) - only decodes fields we care about
struct SupabaseUser: Decodable {
    let id: String
    let email: String?
    let phone: String?
    let aud: String?
    let role: String?
    let createdAt: String?
}

/// Profile response from /api/user/profile
struct ProfileAPIResponse: Decodable {
    let success: Bool?
    let user: ProfileUser?
    let error: String?
}

/// Full profile user with app-specific fields
struct ProfileUser: Decodable {
    let id: String
    let email: String?
    let name: String?
    let points: Int?
    let totalPointsEarned: Int?
    let memberSince: String?
    let jobTitle: String?
    let industry: String?
    let bio: String?
    let skills: [String]?
    let linkedinUrl: String?
    let isOpenToNetworking: Bool?
    let avatarUrl: String?
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

// MARK: - Stored Session (for persistence)

struct StoredSession: Codable {
    let accessToken: String
    let userId: String
    let email: String?
}

// MARK: - ViewModel

@MainActor
class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    
    @Published var state: AuthState = .loading
    
    // We can expose the AuthManager's session or just keep a local copy if needed.
    // Ideally, AuthViewModel manages the Login UI state, while AuthManager manages the Session.
    
    @Published var errorMessage: String?
    
    private let authManager = AuthManager.shared
    private let apiClient = APIClient.shared
    
    // Legacy compatibility for views binding to this
    var accessToken: String? {
        return authManager.session?.accessToken
    }
    
    init() {
        // Observe AuthManager
        self.state = authManager.isAuthenticated ? .authenticated : .unauthenticated
        
        // Listen to AuthManager changes to update local state
        authManager.$isAuthenticated
            .receive(on: RunLoop.main)
            .assign(to: &$isAuthenticatedWrapper)
    }
    
    // Wrapper to handle the property wrapper assignment logic
    @Published private var isAuthenticatedWrapper: Bool = false {
        didSet {
            self.state = isAuthenticatedWrapper ? .authenticated : .unauthenticated
        }
    }
    
    func checkSession() async {
        // AuthManager handles this on init, but we can double check or trigger a refresh if needed
        // For now, we assume AuthManager's init logic covers persistence restoration.
        if authManager.isAuthenticated {
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
            let response: LoginAPIResponse = try await apiClient.post("/api/auth/login", body: loginRequest, retryCount: 0)
            
            if response.success == true || response.token != nil || response.session != nil {
                await authManager.login(response: response)
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
        await authManager.signOut()
        self.state = .unauthenticated
    }
}
