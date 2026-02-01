//
//  ProfileStorage.swift
//  TheCoffeeLinks
//
//  Created for Local-First Architecture
//

import Foundation

protocol ProfileStorageProtocol {
    func saveUser(_ user: User)
    func loadUser() -> User?
    func clearUser()
    
    func saveFavorites(_ favorites: [FavoriteItem])
    func loadFavorites() -> [FavoriteItem]?
    
    func saveVouchers(_ vouchers: [Voucher])
    func loadVouchers() -> [Voucher]?
    
    func saveOrderCount(_ count: Int)
    func loadOrderCount() -> Int?
    
    // Timestamp tracking for data freshness
    func saveLastSyncTimestamp(key: String)
    func getLastSyncTimestamp(key: String) -> Date?
    func isDataStale(key: String, maxAge: TimeInterval) -> Bool
}

final class ProfileStorage: ProfileStorageProtocol {
    private let storage: GenericStorageProtocol
    private let key = "user_profile_v1"
    private let favoritesKey = "user_favorites_v1"
    private let vouchersKey = "user_vouchers_v1"
    private let orderCountKey = "user_order_count_v1"
    
    init(storage: GenericStorageProtocol = GenericStorage()) {
        self.storage = storage
    }
    
    func saveUser(_ user: User) {
        try? storage.save(user, key: key)
    }
    
    func loadUser() -> User? {
        return storage.load(User.self, key: key)
    }
    
    func clearUser() {
        storage.remove(key: key)
    }
    
    func saveFavorites(_ favorites: [FavoriteItem]) {
        try? storage.save(favorites, key: favoritesKey)
    }
    
    func loadFavorites() -> [FavoriteItem]? {
        return storage.load([FavoriteItem].self, key: favoritesKey)
    }
    
    func saveVouchers(_ vouchers: [Voucher]) {
        try? storage.save(vouchers, key: vouchersKey)
    }
    
    func loadVouchers() -> [Voucher]? {
        return storage.load([Voucher].self, key: vouchersKey)
    }
    
    func saveOrderCount(_ count: Int) {
        try? storage.save(count, key: orderCountKey)
    }
    
    func loadOrderCount() -> Int? {
        return storage.load(Int.self, key: orderCountKey)
    }
    
    // MARK: - Timestamp Tracking for Data Freshness
    
    func saveLastSyncTimestamp(key: String) {
        let timestamp = Date()
        try? storage.save(timestamp, key: "last_sync_\(key)")
    }
    
    func getLastSyncTimestamp(key: String) -> Date? {
        return storage.load(Date.self, key: "last_sync_\(key)")
    }
    
    func isDataStale(key: String, maxAge: TimeInterval = 300) -> Bool {
        // Default: Data is stale if older than 5 minutes (300 seconds)
        guard let lastSync = getLastSyncTimestamp(key: key) else {
            return true // No timestamp = stale
        }
        return Date().timeIntervalSince(lastSync) > maxAge
    }
}
