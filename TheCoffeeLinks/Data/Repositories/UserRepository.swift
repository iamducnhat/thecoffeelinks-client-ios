//
//  UserRepository.swift
//  thecoffeelinks-client-ios
//
//

import Foundation

final class UserRepository: UserRepositoryProtocol, SyncableDomain, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    private let profileStorage: ProfileStorageProtocol
    private let syncManager: SyncManagerProtocol
    
    var domainKey: String { "user_profile" }
    
    init(networkService: NetworkServiceProtocol, 
         profileStorage: ProfileStorageProtocol = ProfileStorage(),
         syncManager: SyncManagerProtocol) {
        self.networkService = networkService
        self.profileStorage = profileStorage
        self.syncManager = syncManager
        
        // Register for sync
        self.syncManager.register(domain: self)
    }
    
    func sync(reason: SyncReason) async {
        try? await refreshUser()
    }
    
    func getCachedUser() async -> User? {
        return profileStorage.loadUser()
    }
    
    func refreshUser() async throws -> User {
        // 1. Fetch Remote
        let response: UserResponse = try await networkService.get("/api/user/profile", queryItems: nil)
        let remoteUser = response.user
        
        // 2. Reconcile
        profileStorage.saveUser(remoteUser)
        return remoteUser
    }
    
    func getCurrentUser() async throws -> User {
        do {
            return try await refreshUser()
        } catch {
            if let local = profileStorage.loadUser() {
                return local
            }
            throw error
        }
    }
    
    func updateUser(_ user: User) async throws -> User {
        // 1. Optimistic Local Update
        profileStorage.saveUser(user)
        
        // 2. Background Sync
        Task {
            do {
                let response: UserResponse = try await networkService.put("/api/user/profile", body: user)
                self.profileStorage.saveUser(response.user)
            } catch {
                print("Background sync failed for user profile update: \(error)")
            }
        }
        
        return user
    }
    
    func updatePreferences(_ preferences: UserPreferences) async throws -> UserPreferences {
        if var currentUser = profileStorage.loadUser() {
            var newUser = currentUser
            newUser.preferences = preferences
            profileStorage.saveUser(newUser)
        }
        
        // Changed to use /api/user/preferences to match backend convention
        let response: PreferencesResponse = try await networkService.patch("/api/user/preferences", body: preferences)
        return response.preferences
    }
    
    func getCachedStores() async -> [Store]? {
        guard let data: Data = await DependencyContainer.shared.cacheService.get("stores_list") else { return nil }
        return try? JSONDecoder().decode([Store].self, from: data)
    }
    
    func refreshStores(latitude: Double?, longitude: Double?) async throws -> [Store] {
        var queryItems: [URLQueryItem] = []
        if let lat = latitude, let lon = longitude {
            queryItems.append(URLQueryItem(name: "latitude", value: String(lat)))
            queryItems.append(URLQueryItem(name: "longitude", value: String(lon)))
        }
        let response: StoresResponse = try await networkService.get("/api/stores", queryItems: queryItems.isEmpty ? nil : queryItems)
        
        if let data = try? JSONEncoder().encode(response.stores) {
            await DependencyContainer.shared.cacheService.set("stores_list", value: data, ttl: 86400)
        }
        
        return response.stores
    }
    
    func getStores(latitude: Double?, longitude: Double?) async throws -> [Store] {
        if let data: Data = await DependencyContainer.shared.cacheService.get("stores_list"),
           let cached = try? JSONDecoder().decode([Store].self, from: data) {
            return cached
        }
        return try await refreshStores(latitude: latitude, longitude: longitude)
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
    private let profileStorage: ProfileStorageProtocol
    
    init(networkService: NetworkServiceProtocol, profileStorage: ProfileStorageProtocol = ProfileStorage()) {
        self.networkService = networkService
        self.profileStorage = profileStorage
    }
    
    func getCachedFavorites() async -> [FavoriteItem]? {
        return profileStorage.loadFavorites()
    }
    
    func refreshFavorites() async throws -> [FavoriteItem] {
        let response: FavoritesResponse = try await networkService.get("/api/user/favorites", queryItems: nil)
        profileStorage.saveFavorites(response.favorites)
        return response.favorites
    }
    
    func getFavorites() async throws -> [FavoriteItem] {
        if let cached = profileStorage.loadFavorites() {
             Task { _ = try? await refreshFavorites() }
            return cached
        }
        return try await refreshFavorites()
    }
    
    func addFavorite(product: Product, customization: OrderCustomization, nickname: String?, notes: String?) async throws -> FavoriteItem {
        let response: FavoriteResponse = try await networkService.post("/api/user/favorites", body: AddFavoriteRequest(productId: product.id, customization: customization, nickname: nickname, notes: notes))
        
        // Optimistic update
        if var current = profileStorage.loadFavorites() {
            current.append(response.favorite)
            profileStorage.saveFavorites(current)
        } else {
             _ = try? await refreshFavorites()
        }
        
        return response.favorite
    }
    
    func updateFavorite(_ favorite: FavoriteItem) async throws -> FavoriteItem {
        // Optimistic update
        if var current = profileStorage.loadFavorites(), let index = current.firstIndex(where: { $0.id == favorite.id }) {
            current[index] = favorite
            profileStorage.saveFavorites(current)
        }
        
        let response: FavoriteResponse = try await networkService.put("/api/user/favorites/\(favorite.id)", body: favorite)
        // Confirm update
        if var current = profileStorage.loadFavorites(), let index = current.firstIndex(where: { $0.id == favorite.id }) {
            current[index] = response.favorite
            profileStorage.saveFavorites(current)
        }
        return response.favorite
    }
    
    func removeFavorite(id: String) async throws {
        // Optimistic delete
        if var current = profileStorage.loadFavorites() {
            current.removeAll { $0.id == id }
            profileStorage.saveFavorites(current)
        }
        
        try await networkService.delete("/api/user/favorites/\(id)", queryItems: nil)
    }
    
    func reorderFavorites(ids: [String]) async throws {
        // Optimistic reorder
        if var current = profileStorage.loadFavorites() {
            // Sort current based on ids order
            let map = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
            let sorted = ids.compactMap { map[$0] }
            if sorted.count == current.count {
                profileStorage.saveFavorites(sorted)
            }
        }
        
        let _: EmptyResponse = try await networkService.put("/api/user/favorites/reorder", body: ReorderRequest(ids: ids))
    }
}

// MARK: - Voucher Repository

final class VoucherRepository: VoucherRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    private let profileStorage: ProfileStorageProtocol
    private let syncManager: SyncManagerProtocol
    
    var domainKey: String { "user_vouchers" }
    
    init(networkService: NetworkServiceProtocol, 
         profileStorage: ProfileStorageProtocol = ProfileStorage(), 
         syncManager: SyncManagerProtocol) {
        self.networkService = networkService
        self.profileStorage = profileStorage
        self.syncManager = syncManager
    }
    
    func getCachedVouchers() async -> [Voucher]? {
        return profileStorage.loadVouchers()
    }
    
    func refreshVouchers() async throws -> [Voucher] {
        let response: VouchersResponse = try await networkService.get("/api/vouchers", queryItems: nil)
        profileStorage.saveVouchers(response.vouchers)
        return response.vouchers
    }
    
    func getVouchers() async throws -> [Voucher] {
        if let cached = profileStorage.loadVouchers() {
             Task { _ = try? await refreshVouchers() }
            return cached
        }
        return try await refreshVouchers()
    }
    
    func validateVoucher(code: String, subtotal: Double, mode: OrderingMode) async throws -> VoucherValidation {
        struct ValidateRequest: Encodable {
            let code: String
            let orderTotal: Double
        }
        let response: VoucherValidationResponse = try await networkService.post("/api/vouchers", body: ValidateRequest(code: code, orderTotal: subtotal))
        return response.validation
    }
    
    func fetchAndDistributeVouchers(userId: String) async throws -> [Voucher] {
        struct DistributeRequest: Encodable { let userId: String }
        let response: VouchersResponse = try await networkService.post("/api/vouchers/distribute", body: DistributeRequest(userId: userId))
        profileStorage.saveVouchers(response.vouchers)
        return response.vouchers
    }
}

// MARK: - Social Repository

final class SocialRepository: SocialRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    private let storeStorage: StoreStorageProtocol
    
    init(networkService: NetworkServiceProtocol, storeStorage: StoreStorageProtocol = StoreStorage()) {
        self.networkService = networkService
        self.storeStorage = storeStorage
    }
    
    func getPresences(storeId: String) async throws -> [StorePresence] {
        if let cached = storeStorage.loadPresence(for: storeId) {
            Task { _ = try? await refreshPresences(storeId: storeId) }
            return cached
        }
        return try await refreshPresences(storeId: storeId)
    }
    
    private func refreshPresences(storeId: String) async throws -> [StorePresence] {
        let response: PresenceResponse = try await networkService.get("/api/social/presence", queryItems: [URLQueryItem(name: "storeId", value: storeId)])
        storeStorage.savePresence(response.presences, for: storeId)
        return response.presences
    }
    
    func checkIn(storeId: String, status: PresenceStatus) async throws -> StorePresence {
        let response: CheckInResponse = try await networkService.post("/api/social/check-in", body: CheckInRequest(storeId: storeId, status: status))
        
        if var cached = storeStorage.loadPresence(for: storeId) {
            cached.removeAll { $0.userId == response.presence.userId }
            cached.append(response.presence)
            storeStorage.savePresence(cached, for: storeId)
        } else {
             storeStorage.savePresence([response.presence], for: storeId)
        }
        
        return response.presence
    }
    
    func checkOut(storeId: String) async throws {
        let _: EmptyResponse = try await networkService.post("/api/social/check-out", body: CheckOutRequest(storeId: storeId))
        _ = try? await refreshPresences(storeId: storeId)
    }
    
    func updateStatus(_ status: PresenceStatus) async throws {
        struct ModeRequest: Encodable { let mode: String }
        let _: EmptyResponse = try await networkService.patch("/api/social/presence", body: ModeRequest(mode: status.rawValue))
    }
    
    func updateMode(_ mode: ConnectionMode) async throws {
        struct ModeRequest: Encodable { let mode: String }
        let _: EmptyResponse = try await networkService.patch("/api/social/presence", body: ModeRequest(mode: mode.rawValue))
    }
    
    func getConnections() async throws -> [Connection] {
        let response: ConnectionsResponse = try await networkService.get("/api/social/connections", queryItems: nil)
        return response.connections
    }
    
    func sendConnectionRequest(toUserId: String, message: String?) async throws -> ConnectionRequest {
        struct ConnectBody: Encodable { let targetUserId: String }
        let response: ConnectResponse = try await networkService.post("/api/social/connect", body: ConnectBody(targetUserId: toUserId))
        return response.request
    }
    
    func respondToRequest(id: String, accept: Bool) async throws {
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
        throw SocialError.reportFailed
    }
    
    func claimTreat(id: String) async throws -> CoffeeTreat {
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
