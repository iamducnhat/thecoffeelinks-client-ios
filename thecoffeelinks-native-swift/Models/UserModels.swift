import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let fullName: String?
    let avatarUrl: String?
    let points: Int?
    
    // Networking fields
    let jobTitle: String?
    let industry: String?
    let bio: String?
    let linkedinUrl: String?
    let isOpenToNetworking: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name" // or "name" depending on profile schema, typically full_name
        case avatarUrl = "avatar_url"
        case points
        case jobTitle = "job_title"
        case industry
        case bio
        case linkedinUrl = "linkedin_url"
        case isOpenToNetworking = "is_open_to_networking"
    }
}

struct UpdateProfileParams: Encodable {
    var fullName: String?
    var jobTitle: String?
    var industry: String?
    var bio: String?
    var linkedinUrl: String?
    var isOpenToNetworking: Bool?
    
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case jobTitle = "job_title"
        case industry
        case bio
        case linkedinUrl = "linkedin_url"
        case isOpenToNetworking = "is_open_to_networking"
    }
}
