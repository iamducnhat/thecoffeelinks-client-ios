import Foundation

// MARK: - API Response Wrappers

struct UserProfileResponse: Codable {
    let user: User?
    let profile: User?
    let error: String?
    
    var userData: User? {
        user ?? profile
    }
}

// MARK: - UserService

class UserService: UserServiceProtocol {
    private let apiClient = APIClient.shared
    
    func getCurrentUser() async throws -> User {
        let response: UserProfileResponse = try await apiClient.get("/api/user/profile")
        guard let user = response.userData else {
            throw APIError.notFound
        }
        return user
    }
    
    func updateProfile(userId: String, params: UpdateProfileParams) async throws -> User {
        let response: UserProfileResponse = try await apiClient.patch("/api/user/profile", body: params)
        guard let user = response.userData else {
            throw APIError.invalidResponse
        }
        return user
    }
}
