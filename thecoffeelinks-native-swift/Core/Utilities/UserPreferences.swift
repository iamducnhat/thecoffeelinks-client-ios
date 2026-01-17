//
//  UserPreferences.swift
//  thecoffeelinks-native-swift
//
//  User preferences for speed optimizations
//

import Foundation

final class SpeedPreferences: Sendable {
    private let defaults = UserDefaults.standard
    
    // Keys
    private enum Keys {
        static let lastPaymentMethod = "lastPaymentMethod"
        static let lastStoreId = "lastStoreId"
        static let lastOrderingMode = "lastOrderingMode"
        static let lastDeliveryAddressId = "lastDeliveryAddressId"
    }
    
    // MARK: - Payment Method
    
    var lastPaymentMethod: PaymentMethod? {
        get {
            guard let raw = defaults.string(forKey: Keys.lastPaymentMethod) else { return nil }
            return PaymentMethod(rawValue: raw)
        }
        set {
            defaults.set(newValue?.rawValue, forKey: Keys.lastPaymentMethod)
        }
    }
    
    // MARK: - Store
    
    var lastStoreId: String? {
        get { defaults.string(forKey: Keys.lastStoreId) }
        set { defaults.set(newValue, forKey: Keys.lastStoreId) }
    }
    
    // MARK: - Ordering Mode
    
    var lastOrderingMode: OrderingMode? {
        get {
            guard let raw = defaults.string(forKey: Keys.lastOrderingMode) else { return nil }
            return OrderingMode(rawValue: raw)
        }
        set {
            defaults.set(newValue?.rawValue, forKey: Keys.lastOrderingMode)
        }
    }
    
    // MARK: - Delivery Address
    
    var lastDeliveryAddressId: String? {
        get { defaults.string(forKey: Keys.lastDeliveryAddressId) }
        set { defaults.set(newValue, forKey: Keys.lastDeliveryAddressId) }
    }
    
    // MARK: - Update Methods
    
    func updateLastUsed(paymentMethod: PaymentMethod) {
        lastPaymentMethod = paymentMethod
    }
    
    func updateLastUsed(storeId: String) {
        lastStoreId = storeId
    }
    
    func updateLastUsed(orderingMode: OrderingMode) {
        lastOrderingMode = orderingMode
    }
    
    func updateLastUsed(deliveryAddressId: String) {
        lastDeliveryAddressId = deliveryAddressId
    }
}
