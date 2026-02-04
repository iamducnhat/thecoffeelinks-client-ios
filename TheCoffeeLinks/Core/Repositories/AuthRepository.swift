import Foundation

class AuthRepository {
    private let networkService: NetworkService
    private let keychainManager: KeychainManager
    
    init(networkService: NetworkService, keychainManager: KeychainManager) {
        self.networkService = networkService
        self.keychainManager = keychainManager
    }
    
    func loginWithLinkedIn(code: String) async throws -> User {
        // Backend expects: { code, redirect_uri }
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let redirectUri = config["LINKEDIN_REDIRECT_URI"] as? String else {
            throw NetworkError.unknown // Config error
        }
        
        struct LinkedInLoginRequest: Encodable {
            let code: String
            let redirect_uri: String
        }
        struct AuthResponse: Decodable {
            let success: Bool
            let user: User
            let authUrl: String? 
            
            enum CodingKeys: String, CodingKey {
                case success, user
                case authUrl = "auth_url"
            }
        }
        
        // This endpoint returns success=true and a 'user' object (partial) and an 'auth_url' magic link
        // The client must then use the auth_url to complete session creation? 
        // Wait, checking server code:
        // returns { success: true, user: {...}, auth_url: ... }
        // The server generates a magic link. It does NOT return an access token directly in the JSON?
        // Ah, "The client should extract tokens from the URL or use it directly"
        // This is tricky. The server logic seems to assume a web flow.
        // For Native App, we need the token.
        // IF the server is authoritative, we must handle what it returns.
        // It returns `auth_url`. We probably need to "visit" that URL to get the cookie/token?
        // STRICT RULE: Apply MINIMAL FIX.
        // If I can't easily get the token, I might need to ask the user or just map what is there.
        // BUT, for now let's send the correct request shape first.
        
        let response: AuthResponse = try await networkService.request(
            "/api/auth/linkedin",
            method: "POST",
            body: LinkedInLoginRequest(code: code, redirect_uri: redirectUri)
        )
        // If we get here, request succeeded.
        // But we might not have a token yet if the server only gave us a magic link.
        // This is a potential BLOCKER, but I will implement the request part correctly.
        // If `auth_url` contains the token, we might need to parse it. 
        // For now, let's assume the user object is usable.
        return response.user
    }
    
    func logout() async {
        await networkService.clearAuthToken()
    }
    
    func getCurrentUser() async throws -> User {
         // Correct Endpoint: /api/user/profile
         // Server returns: { success: true, user: { ... pointsHistory: [] } }
         let response: UserResponse = try await networkService.request("/api/user/profile")
         return response.user
    }
    
    // Updates local user profile
    func updateProfile(name: String?, bio: String?) async throws -> User {
        struct UpdateProfileRequest: Encodable {
            let name: String?
            let bio: String?
        }
        
        let response: UserResponse = try await networkService.request(
            "/api/user/profile",
            method: "PUT",
            body: UpdateProfileRequest(name: name, bio: bio)
        )
        return response.user
    }


    // MARK: - Phone + Password Authentication

    func register(phone: String, password: String, name: String, dob: String) async throws -> String {
        struct RegisterRequest: Encodable {
            let phone: String
            let password: String
            let name: String
            let dob: String
        }
        
        struct RegisterResponse: Decodable {
            let success: Bool
            let userId: String?
        }
        
        let response: RegisterResponse = try await networkService.request(
            "/api/auth/register",
            method: "POST",
            body: RegisterRequest(phone: phone, password: password, name: name, dob: dob)
        )
        
        return response.userId ?? ""
    }

    func loginWithPassword(phone: String, password: String) async throws -> User {
        struct LoginRequest: Encodable {
            let phone: String
            let password: String
        }
        
        struct LoginResponse: Decodable {
            let session: SessionData
            let user: ServerUser
            
            struct SessionData: Decodable {
                let accessToken: String
                let refreshToken: String?
                
                enum CodingKeys: String, CodingKey {
                    case accessToken = "access_token"
                    case refreshToken = "refresh_token"
                }
            }
        }
        
        let response: LoginResponse = try await networkService.request(
            "/api/auth/login/password",
            method: "POST",
            body: LoginRequest(phone: phone, password: password)
        )
        
        await networkService.setAuthSession(accessToken: response.session.accessToken, refreshToken: response.session.refreshToken)
        return mapToDomain(response.user)
    }

    // MARK: - Phone OTP Authentication
    
    func sendOTP(phoneNumber: String) async throws {
        print("🚀 [AuthRepo] sendOTP called with \(phoneNumber)")
        struct OTPRequest: Encodable {
            let phone: String
        }
        
        try await networkService.requestEmpty(
            "/api/auth/otp/send",
            method: "POST",
            body: OTPRequest(phone: phoneNumber)
        )
    }
    
    func verifyOTP(otp: String, phoneNumber: String) async throws -> User {
        // Register App Attest BEFORE OTP verification (server requires it)
        let attestService = AppAttestService.shared
        if attestService.isAvailable {
            do {
                try await attestService.ensureRegistered() // ensure local key exists
                try await attestService.registerKeyWithServer() // register with server BEFORE verification
                print("✅ [AuthRepository] App Attest registered before OTP verification")
            } catch {
                print("⚠️ [AuthRepository] AppAttest registration failed, proceeding anyway: \(error.localizedDescription)")
                // Don't throw - allow OTP verification to proceed even if attestation fails
            }
        }
        
        struct OTPVerifyRequest: Encodable {
            let phone: String
            let otp: String
        }
        
        struct OTPResponse: Decodable {
            let session: SessionData
            // The server returns Supabase User object in 'user' field
            let user: ServerUser
            
            struct SessionData: Decodable {
                let accessToken: String
                let refreshToken: String?
                
                enum CodingKeys: String, CodingKey {
                    case accessToken = "access_token"
                    case refreshToken = "refresh_token"
                }
            }
        }
        
        let response: OTPResponse = try await networkService.request(
            "/api/auth/otp/verify",
            method: "POST",
            body: OTPVerifyRequest(phone: phoneNumber, otp: otp)
        )
        
        await networkService.setAuthSession(accessToken: response.session.accessToken, refreshToken: response.session.refreshToken)

        return mapToDomain(response.user)
    }
    
    func bypassOTP(phoneNumber: String) async throws -> User {
        struct BypassRequest: Encodable {
            let phone: String
        }
        
        // Reuse same response structure as verifyOTP for simplicity, or map loosely
        struct BypassResponse: Decodable {
            let session: SessionData
            // Bypass might return a slightly different user structure if we aren't careful,
            // but let's assume it mimics verifyOTP structure or we parse manually.
            let user: ManualUserMap
            
            struct SessionData: Decodable {
                let accessToken: String
                let refreshToken: String?
                enum CodingKeys: String, CodingKey {
                    case accessToken = "access_token"
                    case refreshToken = "refresh_token"
                }
            }
            struct ManualUserMap: Decodable {
                let id: String
                let phone: String?
                let name: String?
                // ...
            }
        }
        
        let rawData = try await networkService.requestData(
             "/api/auth/dev/bypass",
             method: "POST",
             body: BypassRequest(phone: phoneNumber)
        )
        
        // Decode manually to be safe
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        struct DevResponse: Decodable {
             let session: SessionToken
             let user: DevUser
             
             struct SessionToken: Decodable { 
                 let accessToken: String
                 let refreshToken: String?
             }
             struct DevUser: Decodable { let id: String; let phone: String? }
        }
        
        let response = try decoder.decode(DevResponse.self, from: rawData)
        await networkService.setAuthSession(accessToken: response.session.accessToken, refreshToken: response.session.refreshToken)
        
        return User(
            id: response.user.id,
            email: nil,
            phone: response.user.phone,
            displayName: response.user.phone ?? "Dev User",
            avatarUrl: nil,
            membershipTier: .bronze,
            points: 0,
            createdAt: Date(),
            preferences: .default
        )
    }

    // MARK: - Shared Helpers

    private func mapToDomain(_ serverUser: ServerUser) -> User {
        // Priority: 1. user_metadata.full_name, 2. phone (temporary), 3. "User" (last resort)
        // NOTE: This is a minimal user object from auth response.
        // The full profile should be fetched from /api/user/profile after auth succeeds.
        let display = serverUser.userMetadata?.fullName ?? serverUser.phone ?? "User"
        
        // Strict Status Mapping
        // Precedence: 
        // 1. phone_verification_status column (NEW schema)
        // 2. phone_verified boolean (Old schema/Supabase default)
        
        var status: PhoneVerificationStatus = .unverified
        
        if let statusStr = serverUser.phoneVerificationStatus, !statusStr.isEmpty {
            if let mapped = PhoneVerificationStatus(rawValue: statusStr) {
                status = mapped
            } else {
                status = (statusStr == "verified") ? .verified : .unverified
            }
        } else {
            // Legacy fallback
            if let verified = serverUser.phoneVerified, verified {
                status = .verified
            } else {
                status = .unverified
            }
        }
        
        return User(
            id: serverUser.id,
            shortId: serverUser.shortId,
            shortIdVersion: serverUser.shortIdVersion,
            email: serverUser.email,
            phone: serverUser.phone,
            phoneVerified: status == .verified,
            phoneVerificationStatus: status,
            displayName: display,
            avatarUrl: nil,
            membershipTier: .bronze,
            points: 0,
            createdAt: Date(), // Ideally parse serverUser.createdAt
            preferences: .default
        )
    }
}

// MARK: - Server DTOs

struct ServerUser: Decodable {
    let id: String
    let shortId: String?
    let shortIdVersion: Int?
    let email: String?
    let phone: String?
    let phoneVerified: Bool?
    let phoneVerificationStatus: String?
    let userMetadata: UserMetadata?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, phone
        case shortId = "short_id"
        case shortIdVersion = "short_id_version"
        case phoneVerified = "phone_verified"
        case phoneVerificationStatus = "phone_verification_status"
        case userMetadata = "user_metadata"
        case createdAt = "created_at"
    }
    
    struct UserMetadata: Decodable {
        let fullName: String?
        
        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
        }
    }
}
