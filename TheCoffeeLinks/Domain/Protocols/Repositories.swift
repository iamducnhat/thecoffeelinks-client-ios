//
//  Repositories.swift
//  thecoffeelinks-client-ios
//
//  Repository protocols for data access - NO SwiftUI imports
//

import Foundation

// MARK: - Order Repository

protocol OrderRepositoryProtocol: Sendable {
    func createOrder(_ request: CreateOrderRequest) async throws -> Order
    func getOrder(id: String) async throws -> Order
    func getOrders(status: OrderStatus?, limit: Int, offset: Int) async throws -> OrdersListResponse
    func getActiveOrders() async throws -> [Order]
    func cancelOrder(id: String, reason: String?) async throws -> Order
    func undoCancelOrder(id: String) async throws -> Order
    func reportOrderIssue(id: String, category: String, subject: String, description: String?) async throws
}

// MARK: - Product Repository

protocol ProductRepositoryProtocol: Sendable {
    func getMenu(storeId: String?) async throws -> Menu
    func getCachedMenu(storeId: String?) async -> Menu?
    func refreshMenu(storeId: String?) async throws -> Menu
    func getProducts(categoryId: String?) async throws -> [Product]
    func getProduct(id: String) async throws -> Product
    func getCategories() async throws -> [Category]
    func getToppings() async throws -> [Topping]
    func getPopularProducts(period: String, limit: Int) async throws -> [PopularProduct]
    func getCachedPopularProducts() async -> [PopularProduct]?
    func refreshPopularProducts(period: String, limit: Int) async throws -> [PopularProduct]
    func searchProducts(query: String) async throws -> [Product]
}

extension ProductRepositoryProtocol {
    func getMenu() async throws -> Menu {
        try await getMenu(storeId: nil)
    }

    func getCachedMenu() async -> Menu? {
        await getCachedMenu(storeId: nil)
    }

    func refreshMenu() async throws -> Menu {
        try await refreshMenu(storeId: nil)
    }
}

// MARK: - Delivery Repository

protocol DeliveryRepositoryProtocol: Sendable {
    func getAddresses() async throws -> [DeliveryAddress]
    func saveAddress(_ address: DeliveryAddress) async throws -> DeliveryAddress
    func updateAddress(_ address: DeliveryAddress) async throws -> DeliveryAddress
    func deleteAddress(id: String) async throws
    func setDefaultAddress(id: String) async throws
    func checkAvailability(addressId: String?, latitude: Double?, longitude: Double?, storeId: String) async throws -> DeliveryAvailability
    func getDeliveryZones(storeId: String) async throws -> [DeliveryZone]
    func getDeliveryTracking(orderId: String) async throws -> DeliveryTracking
}

// MARK: - Store Repository

protocol StoreRepositoryProtocol: Sendable {
    func getStores() async throws -> [Store]
    func refreshStores() async throws -> [Store]
    func getStore(id: String) async throws -> Store
    func getNearestStore(latitude: Double, longitude: Double) async throws -> Store?
}

// MARK: - User Repository

protocol UserRepositoryProtocol: Sendable {
    func getCurrentUser() async throws -> User
    func getCachedUser() async -> User?
    func refreshUser() async throws -> User
    func updateUser(_ user: User) async throws -> User
    func updatePreferences(_ preferences: UserPreferences) async throws -> UserPreferences
    func getStores(latitude: Double?, longitude: Double?) async throws -> [Store]
    func getCachedStores() async -> [Store]?
    func refreshStores(latitude: Double?, longitude: Double?) async throws -> [Store]
    func getStore(id: String) async throws -> Store
}

// MARK: - Favorites Repository

protocol FavoritesRepositoryProtocol: Sendable {
    func getFavorites() async throws -> [FavoriteItem]
    func getCachedFavorites() async -> [FavoriteItem]?
    func refreshFavorites() async throws -> [FavoriteItem]
    func addFavorite(product: Product, customization: OrderCustomization, nickname: String?, notes: String?) async throws -> FavoriteItem
    func updateFavorite(_ favorite: FavoriteItem) async throws -> FavoriteItem
    func removeFavorite(id: String) async throws
    func reorderFavorites(ids: [String]) async throws
}

// MARK: - Auth Repository

protocol AuthRepositoryProtocol: Sendable {
    func login(_ request: LoginRequest) async throws -> AuthSession
    func logout() async throws
    func refreshSession() async throws -> AuthSession
    func getCurrentSession() async throws -> AuthSession?
    func requestOTP(phone: String) async throws
    func verifyOTP(phone: String, otp: String) async throws -> AuthSession
}

// MARK: - Voucher Repository

protocol VoucherRepositoryProtocol: Sendable {
    func getVouchers() async throws -> [Voucher]
    func getCachedVouchers() async -> [Voucher]?
    func refreshVouchers() async throws -> [Voucher]
    func validateVoucher(code: String, subtotal: Double, mode: OrderingMode) async throws -> VoucherValidation
    func fetchAndDistributeVouchers(userId: String) async throws -> [Voucher]
}

// MARK: - Social Repository

protocol SocialRepositoryProtocol: Sendable {
    func getPresences(storeId: String) async throws -> [StorePresence]
    func checkIn(storeId: String, status: PresenceStatus) async throws -> StorePresence
    func checkOut(storeId: String) async throws
    func updateStatus(_ status: PresenceStatus) async throws
    func updateMode(_ mode: ConnectionMode) async throws
    func getConnections() async throws -> [Connection]
    func sendConnectionRequest(toUserId: String, message: String?) async throws -> ConnectionRequest
    func respondToRequest(id: String, accept: Bool) async throws
    func blockUser(userId: String, reason: String?) async throws -> BlockedUser
    func unblockUser(userId: String) async throws
    func reportUser(userId: String, reason: ReportReason, details: String?) async throws -> Report
    func sendTreat(toUserId: String, amount: Double, message: String?) async throws -> CoffeeTreat
    func claimTreat(id: String) async throws -> CoffeeTreat
}

// MARK: - Prediction Repository (Local)

protocol PredictionRepositoryProtocol: Sendable {
    func getHistory() async -> [PredictionHistoryItem]
    func saveHistory(_ items: [PredictionHistoryItem]) async
    func recordOrder(items: [CartItem], context: PredictionContext) async
    func recordOrderFromHistory(order: Order) async
    func getDismissals() async -> [Date]
    func recordDismissal() async
    func clearDismissals() async
    func getSuppressedCombos() async -> Set<String>
    func suppressCombo(_ key: String) async
    func getLastSyncDate() async -> Date?
    func setLastSyncDate(_ date: Date) async
}
