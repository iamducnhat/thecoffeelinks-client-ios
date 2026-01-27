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
}

final class ProfileStorage: ProfileStorageProtocol {
    private let storage: GenericStorageProtocol
    private let key = "user_profile_v1"
    private let favoritesKey = "user_favorites_v1"
    private let vouchersKey = "user_vouchers_v1"
    
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
}
