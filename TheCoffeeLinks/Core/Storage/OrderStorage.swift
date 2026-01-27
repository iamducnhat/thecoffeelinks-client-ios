//
//  OrderStorage.swift
//  TheCoffeeLinks
//
//  Created for Local-First Architecture
//

import Foundation

struct OrderDraft: Codable {
    var paymentMethod: PaymentMethod
    var selectedAddressId: String?
    var tableId: String?
    var staffNotes: String?
}

protocol OrderStorageProtocol {
    func saveDraft(_ draft: OrderDraft)
    func loadDraft() -> OrderDraft?
    func clearDraft()
}

final class OrderStorage: OrderStorageProtocol {
    private let storage: GenericStorageProtocol
    private let key = "checkout_draft_v1"
    
    init(storage: GenericStorageProtocol = GenericStorage()) {
        self.storage = storage
    }
    
    func saveDraft(_ draft: OrderDraft) {
        try? storage.save(draft, key: key)
    }
    
    func loadDraft() -> OrderDraft? {
        return storage.load(OrderDraft.self, key: key)
    }
    
    func clearDraft() {
        storage.remove(key: key)
    }
}
