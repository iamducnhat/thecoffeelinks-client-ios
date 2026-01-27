//
//  StoreStorage.swift
//  TheCoffeeLinks
//
//  Created for Local-First Architecture
//

import Foundation

protocol StoreStorageProtocol {
    func saveStores(_ stores: [Store])
    func loadStores() -> [Store]?
    
    func savePresence(_ presence: [StorePresence], for storeId: String)
    func loadPresence(for storeId: String) -> [StorePresence]?
}

final class StoreStorage: StoreStorageProtocol {
    private let storage: GenericStorageProtocol
    private let storesKey = "stores_list_v1"
    private let presencePrefix = "store_presence_"
    
    init(storage: GenericStorageProtocol = GenericStorage()) {
        self.storage = storage
    }
    
    func saveStores(_ stores: [Store]) {
        try? storage.save(stores, key: storesKey)
    }
    
    func loadStores() -> [Store]? {
        return storage.load([Store].self, key: storesKey)
    }
    
    func savePresence(_ presence: [StorePresence], for storeId: String) {
        try? storage.save(presence, key: presencePrefix + storeId)
    }
    
    func loadPresence(for storeId: String) -> [StorePresence]? {
        return storage.load([StorePresence].self, key: presencePrefix + storeId)
    }
}
