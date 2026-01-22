//
//  BootstrapService.swift
//  thecoffeelinks-native-swift
//

import Foundation

// MARK: - Bootstrap Models

struct BootstrapResponse: Codable, Sendable {
    let profile: BootstrapProfile?
    let vouchers: [BootstrapVoucher]?
    let versions: [String: Int]?
    let recentPoints: [BootstrapPointsHistory]?
    
    enum CodingKeys: String, CodingKey {
        case profile
        case vouchers
        case versions
        case recentPoints = "recent_points"
    }
}

struct BootstrapProfile: Codable, Sendable {
    let id: String
    let email: String?
    let name: String?
    let phone: String?
    let avatarUrl: String?
    let points: Int
    let shortId: String?
    let membershipTier: String?
    let memberSince: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case phone
        case avatarUrl = "avatar_url"
        case points
        case shortId = "short_id"
        case membershipTier = "membership_tier"
        case memberSince = "member_since"
    }
}

struct BootstrapVoucher: Codable, Sendable {
    let id: String
    let code: String
    let description: String?
    let discountType: String
    let discountAmount: Double?
    let expiresAt: Date?
    let minOrder: Double?
    let maxDiscount: Double?
    let imageUrl: String?
    let isActive: Bool?
    let maxUsesPerUser: Int?
    let userUsesCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case description
        case discountType = "discount_type"
        case discountAmount = "discount_amount"
        case expiresAt = "expires_at"
        case minOrder = "min_order"
        case maxDiscount = "max_discount"
        case imageUrl = "image_url"
        case isActive = "is_active"
        case maxUsesPerUser = "max_uses_per_user"
        case userUsesCount = "user_uses_count"
    }
}

struct BootstrapPointsHistory: Codable, Sendable {
    let id: String
    let type: String
    let points: Int
    let description: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case points
        case description
        case createdAt = "created_at"
    }
}

// MARK: - Bootstrap Service

final class BootstrapService: @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    /// Fetch app bootstrap data using optimized RPC
    /// Returns profile, vouchers, versions, and recent points in single query
    /// Note: Response cached automatically via ETag at NetworkService layer
    nonisolated func getBootstrapData() async throws -> BootstrapResponse {
        print("🚀 Fetching bootstrap data...")
        let response: BootstrapResponse = try await networkService.get("/api/bootstrap", queryItems: nil)
        return response
    }
    
    /// Convert bootstrap data to domain User model
    func convertBootstrapToUser(_ bootstrap: BootstrapResponse) -> User? {
        guard let profile = bootstrap.profile else { return nil }
        
        // Parse membership tier
        let tier: MembershipTier
        if let tierString = profile.membershipTier {
            tier = MembershipTier(rawValue: tierString) ?? .bronze
        } else {
            tier = .bronze
        }
        
        return User(
            id: profile.id,
            shortId: profile.shortId,
            shortIdVersion: 1,
            email: profile.email,
            phone: profile.phone,
            displayName: profile.name ?? "User",
            avatarUrl: profile.avatarUrl,
            membershipTier: tier,
            points: profile.points,
            createdAt: profile.memberSince ?? Date(),
            preferences: .default
        )
    }
    
    /// Get bootstrap vouchers (returns raw bootstrap voucher models)
    func getBootstrapVouchers(_ bootstrap: BootstrapResponse) -> [BootstrapVoucher] {
        return bootstrap.vouchers ?? []
    }
}
