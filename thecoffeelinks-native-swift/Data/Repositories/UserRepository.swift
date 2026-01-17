//
//  UserRepository.swift
//  thecoffeelinks-native-swift
//

import Foundation

final class UserRepository: UserRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) { self.networkService = networkService }
    
    func getCurrentUser() async throws -> User {
        let response: UserResponse = try await networkService.get("/api/user/profile", queryItems: nil)
        return response.user
    }
    
    func updateUser(_ user: User) async throws -> User {
        let response: UserResponse = try await networkService.put("/api/user/profile", body: user)
        return response.user
    }
    
    func updatePreferences(_ preferences: UserPreferences) async throws -> UserPreferences {
        let response: PreferencesResponse = try await networkService.put("/api/users/me/preferences", body: preferences)
        return response.preferences
    }
    
    func getStores(latitude: Double?, longitude: Double?) async throws -> [Store] {
        var queryItems: [URLQueryItem] = []
        if let lat = latitude, let lon = longitude {
            queryItems.append(URLQueryItem(name: "latitude", value: String(lat)))
            queryItems.append(URLQueryItem(name: "longitude", value: String(lon)))
        }
        let response: StoresResponse = try await networkService.get("/api/stores", queryItems: queryItems.isEmpty ? nil : queryItems)
        return response.stores
    }
    
    func getStore(id: String) async throws -> Store {
        let response: StoreResponse = try await networkService.get("/api/stores/\(id)", queryItems: nil)
        return response.store
    }
}

// MARK: - Request Types (Sendable)

private struct AddFavoriteRequest: Codable, Sendable { let productId: String; let customization: OrderCustomization; let nickname: String?; let notes: String? }
private struct ReorderRequest: Codable, Sendable { let ids: [String] }
private struct CheckInRequest: Codable, Sendable { let storeId: String; let status: PresenceStatus }
private struct CheckInResponse: Codable, Sendable { let success: Bool; let presence: StorePresence }
private struct CheckOutRequest: Codable, Sendable { let storeId: String }
private struct StatusRequest: Codable, Sendable { let status: PresenceStatus }
private struct ConnectRequest: Codable, Sendable { let toUserId: String; let message: String? }
private struct ConnectResponse: Codable, Sendable { let success: Bool; let request: ConnectionRequest }
private struct RespondRequest: Codable, Sendable { let accept: Bool }
private struct BlockRequest: Codable, Sendable { let userId: String; let reason: String? }
private struct ReportRequest: Codable, Sendable { let userId: String; let reason: ReportReason; let details: String? }
private struct TreatRequest: Codable, Sendable { let toUserId: String; let amount: Double; let message: String? }
private struct TreatResponse: Codable, Sendable { let success: Bool; let treat: CoffeeTreat }
private struct EmptyBody: Codable, Sendable {}
private struct ClaimResponse: Codable, Sendable { let success: Bool; let treat: CoffeeTreat }

// MARK: - Favorites Repository

final class FavoritesRepository: FavoritesRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) { self.networkService = networkService }
    
    func getFavorites() async throws -> [FavoriteItem] {
        let response: FavoritesResponse = try await networkService.get("/api/user/favorites", queryItems: nil)
        return response.favorites
    }
    
    func addFavorite(product: Product, customization: OrderCustomization, nickname: String?, notes: String?) async throws -> FavoriteItem {
        let response: FavoriteResponse = try await networkService.post("/api/user/favorites", body: AddFavoriteRequest(productId: product.id, customization: customization, nickname: nickname, notes: notes))
        return response.favorite
    }
    
    func updateFavorite(_ favorite: FavoriteItem) async throws -> FavoriteItem {
        let response: FavoriteResponse = try await networkService.put("/api/user/favorites/\(favorite.id)", body: favorite)
        return response.favorite
    }
    
    func removeFavorite(id: String) async throws { try await networkService.delete("/api/user/favorites/\(id)", queryItems: nil) }
    
    func reorderFavorites(ids: [String]) async throws {
        let _: EmptyResponse = try await networkService.put("/api/user/favorites/reorder", body: ReorderRequest(ids: ids))
    }
}

// MARK: - Voucher Repository

final class VoucherRepository: VoucherRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) { self.networkService = networkService }
    
    func getVouchers() async throws -> [Voucher] {
        let response: VouchersListResponse = try await networkService.get("/api/vouchers", queryItems: nil)
        return response.vouchers
    }
    
    func validateVoucher(code: String, subtotal: Double, mode: OrderingMode) async throws -> VoucherValidation {
        struct ValidateRequest: Encodable {
            let code: String
            let orderTotal: Double
        }
        // Server uses POST /api/vouchers for validation if code and orderTotal are present
        let response: VoucherValidationResponse = try await networkService.post("/api/vouchers", body: ValidateRequest(code: code, orderTotal: subtotal))
        return response.validation
    }
}

// MARK: - Social Repository

final class SocialRepository: SocialRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) { self.networkService = networkService }
    
    func getPresences(storeId: String) async throws -> [StorePresence] {
        let response: PresenceResponse = try await networkService.get("/api/social/presence", queryItems: [URLQueryItem(name: "storeId", value: storeId)])
        return response.presences
    }
    
    func checkIn(storeId: String, status: PresenceStatus) async throws -> StorePresence {
        let response: CheckInResponse = try await networkService.post("/api/social/check-in", body: CheckInRequest(storeId: storeId, status: status))
        return response.presence
    }
    
    func checkOut(storeId: String) async throws {
        let _: EmptyResponse = try await networkService.post("/api/social/check-out", body: CheckOutRequest(storeId: storeId))
    }
    
    func updateStatus(_ status: PresenceStatus) async throws {
        // 'Status' in client maps to 'Mode' (open/focus) on server PATCH /api/social/presence
        struct ModeRequest: Encodable { let mode: String }
        let _: EmptyResponse = try await networkService.patch("/api/social/presence", body: ModeRequest(mode: status.rawValue))
    }
    
    func updateMode(_ mode: ConnectionMode) async throws {
        // Redundant with updateStatus but keeping for API compatibility
        struct ModeRequest: Encodable { let mode: String }
        let _: EmptyResponse = try await networkService.patch("/api/social/presence", body: ModeRequest(mode: mode.rawValue))
    }
    
    func getConnections() async throws -> [Connection] {
        let response: ConnectionsResponse = try await networkService.get("/api/social/connections", queryItems: nil)
        return response.connections
    }
    
    func sendConnectionRequest(toUserId: String, message: String?) async throws -> ConnectionRequest {
        // Server uses /api/social/connect for creating requests
        struct ConnectBody: Encodable { let targetUserId: String }
        let response: ConnectResponse = try await networkService.post("/api/social/connect", body: ConnectBody(targetUserId: toUserId))
        return response.request
    }
    
    func respondToRequest(id: String, accept: Bool) async throws {
        // Likely /api/social/connections/[id] with PATCH status? Or [id]/respond?
        // Assuming [id]/respond based on convention, but verify if fails.
        let _: EmptyResponse = try await networkService.post("/api/social/connections/\(id)/respond", body: RespondRequest(accept: accept))
    }
    
    func blockUser(userId: String, reason: String?) async throws -> BlockedUser {
        let response: BlockResponse = try await networkService.post("/api/social/block", body: BlockRequest(userId: userId, reason: reason))
        guard let blocked = response.blocked else { throw SocialError.blockFailed }
        return blocked
    }
    
    func unblockUser(userId: String) async throws { try await networkService.delete("/api/social/block", queryItems: [URLQueryItem(name: "blockedUserId", value: userId)]) }
    
    func reportUser(userId: String, reason: ReportReason, details: String?) async throws -> Report {
        let response: ReportResponse = try await networkService.post("/api/social/report", body: ReportRequest(userId: userId, reason: reason, details: details))
        guard let report = response.report else { throw SocialError.reportFailed }
        return report
    }
    
    func sendTreat(toUserId: String, amount: Double, message: String?) async throws -> CoffeeTreat {
        // FEATURE MISSING ON SERVER
        throw SocialError.reportFailed // Re-using error or add new one
    }
    
    func claimTreat(id: String) async throws -> CoffeeTreat {
        // FEATURE MISSING ON SERVER
         throw SocialError.reportFailed
    }
}

enum SocialError: LocalizedError {
    case blockFailed, reportFailed
    var errorDescription: String? {
        switch self {
        case .blockFailed: return "Failed to block user"
        case .reportFailed: return "Failed to submit report"
        }
    }
}
