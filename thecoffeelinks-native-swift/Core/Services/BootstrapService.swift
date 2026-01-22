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
    let fullName: String?
    let avatarUrl: String?
    let points: Int
    let totalPointsEarned: Int
    let shortId: String?
    let memberSince: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case points
        case totalPointsEarned = "total_points_earned"
        case shortId = "short_id"
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
    let minOrder: Int?
    let maxDiscount: Int?
    let imageUrl: String?
    
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

@MainActor
final class BootstrapService: @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let cacheKey = "app_bootstrap"
    
    init(networkService: NetworkServiceProtocol, cacheService: CacheServiceProtocol) {
        self.networkService = networkService
        self.cacheService = cacheService
    }
    
    /// Fetch app bootstrap data using optimized RPC
    /// Returns profile, vouchers, versions, and recent points in single query
    func getBootstrapData() async throws -> BootstrapResponse {
        // Try cache first
        if let cached: BootstrapResponse = await cacheService.get(cacheKey) {
            print("✅ Using cached bootstrap data")
            return cached
        }
        
        // Fetch from server using optimized RPC
        print("🚀 Fetching bootstrap data from server...")
        let response: BootstrapResponse = try await networkService.get("/api/bootstrap", queryItems: nil)
        
        // Cache for 5 minutes
        await cacheService.set(cacheKey, value: response, ttl: 300)
        
        return response
    }
    
    /// Convert bootstrap data to domain models
    func convertBootstrapToUser(_ bootstrap: BootstrapResponse) -> User? {
        guard let profile = bootstrap.profile else { return nil }
        
        return User(
            id: profile.id,
            email: profile.email ?? "",
            name: profile.name ?? "",
            fullName: profile.fullName,
            avatarUrl: profile.avatarUrl,
            points: profile.points,
            totalPointsEarned: profile.totalPointsEarned,
            shortId: profile.shortId ?? "",
            memberSince: profile.memberSince ?? Date()
        )
    }
    
    /// Convert bootstrap vouchers to domain Voucher models
    func convertBootstrapVouchers(_ bootstrap: BootstrapResponse) -> [Voucher] {
        guard let vouchers = bootstrap.vouchers else { return [] }
        
        return vouchers.compactMap { bv in
            Voucher(
                id: bv.id,
                code: bv.code,
                description: bv.description ?? "",
                discountType: bv.discountType,
                discountAmount: bv.discountAmount ?? 0,
                expiresAt: bv.expiresAt,
                minOrder: bv.minOrder ?? 0,
                maxDiscount: bv.maxDiscount,
                imageUrl: bv.imageUrl,
                isUsed: false
            )
        }
    }
    
    /// Clear cached bootstrap data (call on logout or refresh)
    func clearCache() async {
        await cacheService.remove(cacheKey)
    }
}
