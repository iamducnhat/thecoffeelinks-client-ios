import Foundation

/// User model - APIClient uses .convertFromSnakeCase so no CodingKeys needed
struct User: Decodable, Identifiable {
    let id: String
    let email: String?
    let fullName: String?
    let name: String?  // Some APIs use "name" instead of "full_name"
    let avatarUrl: String?
    let points: Int?
    
    // Networking fields
    let jobTitle: String?
    let industry: String?
    let bio: String?
    let linkedinUrl: String?
    let isOpenToNetworking: Bool?
    
    // Computed for compatibility
    var displayName: String { fullName ?? name ?? "Guest" }
}

/// UpdateProfileParams - needs CodingKeys for ENCODING (sending to API)
struct UpdateProfileParams: Encodable {
    var fullName: String?
    var jobTitle: String?
    var industry: String?
    var bio: String?
    var linkedinUrl: String?
    var isOpenToNetworking: Bool?
    
    // Note: APIClient uses .convertToSnakeCase for encoding, so no CodingKeys needed
}
