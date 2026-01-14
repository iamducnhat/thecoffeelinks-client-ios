//
//  UserPreferencesManager.swift
//  thecoffeelinks-native-swift
//
//  Smart defaults and preference storage per Blueprint
//

import Foundation
import Combine
import CoreLocation

// MARK: - User Preferences Manager

@MainActor
class UserPreferencesManager: ObservableObject {
    static let shared = UserPreferencesManager()
    
    // Default order preferences
    @Published var defaultSize: String {
        didSet { UserDefaults.standard.set(defaultSize, forKey: Keys.defaultSize) }
    }
    
    @Published var defaultIce: String {
        didSet { UserDefaults.standard.set(defaultIce, forKey: Keys.defaultIce) }
    }
    
    @Published var defaultSugar: String {
        didSet { UserDefaults.standard.set(defaultSugar, forKey: Keys.defaultSugar) }
    }
    
    // Payment preferences
    @Published var lastPaymentMethod: String? {
        didSet { UserDefaults.standard.set(lastPaymentMethod, forKey: Keys.lastPaymentMethod) }
    }
    
    @Published var savedCards: [SavedCard] {
        didSet {
            if let encoded = try? JSONEncoder().encode(savedCards) {
                UserDefaults.standard.set(encoded, forKey: Keys.savedCards)
            }
        }
    }
    
    // Location preferences
    @Published var lastSelectedStoreId: String? {
        didSet { UserDefaults.standard.set(lastSelectedStoreId, forKey: Keys.lastStoreId) }
    }
    
    @Published var preferredStoreIds: [String] {
        didSet { UserDefaults.standard.set(preferredStoreIds, forKey: Keys.preferredStores) }
    }
    
    // Order method
    @Published var preferredOrderMethod: OrderMethod {
        didSet { UserDefaults.standard.set(preferredOrderMethod.rawValue, forKey: Keys.orderMethod) }
    }
    
    private init() {
        // Load from UserDefaults
        self.defaultSize = UserDefaults.standard.string(forKey: Keys.defaultSize) ?? "M"
        self.defaultIce = UserDefaults.standard.string(forKey: Keys.defaultIce) ?? "Normal"
        self.defaultSugar = UserDefaults.standard.string(forKey: Keys.defaultSugar) ?? "Normal"
        self.lastPaymentMethod = UserDefaults.standard.string(forKey: Keys.lastPaymentMethod)
        self.lastSelectedStoreId = UserDefaults.standard.string(forKey: Keys.lastStoreId)
        self.preferredStoreIds = UserDefaults.standard.stringArray(forKey: Keys.preferredStores) ?? []
        
        // Load saved cards
        if let data = UserDefaults.standard.data(forKey: Keys.savedCards),
           let decoded = try? JSONDecoder().decode([SavedCard].self, from: data) {
            self.savedCards = decoded
        } else {
            self.savedCards = []
        }
        
        // Load order method
        if let methodRaw = UserDefaults.standard.string(forKey: Keys.orderMethod),
           let method = OrderMethod(rawValue: methodRaw) {
            self.preferredOrderMethod = method
        } else {
            self.preferredOrderMethod = .pickup
        }
    }
    
    // MARK: - Smart Defaults
    
    /// Get default customization for new orders
    func defaultCustomization() -> OrderCustomization {
        return OrderCustomization(
            size: defaultSize,
            ice: defaultIce,
            sugar: defaultSugar,
            toppings: nil
        )
    }
    
    /// Update defaults based on completed order
    func learnFromOrder(customization: OrderCustomization) {
        // Simple learning: update defaults if consistently different
        // This can be replaced with more sophisticated ML later
        defaultSize = customization.size
        if let ice = customization.ice { defaultIce = ice }
        if let sugar = customization.sugar { defaultSugar = sugar }
    }
    
    /// Remember payment method after successful checkout
    func rememberPaymentMethod(_ method: String) {
        lastPaymentMethod = method
    }
    
    /// Add a saved card
    func addSavedCard(_ card: SavedCard) {
        savedCards.append(card)
    }
    
    /// Remove a saved card
    func removeSavedCard(id: String) {
        savedCards.removeAll { $0.id == id }
    }
    
    /// Get default saved card (first one)
    var defaultCard: SavedCard? {
        savedCards.first
    }
    
    // MARK: - Store Selection
    
    /// Record store visit
    func recordStoreVisit(_ storeId: String) {
        lastSelectedStoreId = storeId
        if !preferredStoreIds.contains(storeId) {
            preferredStoreIds.insert(storeId, at: 0)
            if preferredStoreIds.count > 5 {
                preferredStoreIds.removeLast()
            }
        }
    }
    
    /// Check if store is frequently visited
    func isFrequentStore(_ storeId: String) -> Bool {
        preferredStoreIds.contains(storeId)
    }
}

// MARK: - Keys

private enum Keys {
    static let defaultSize = "user_default_size"
    static let defaultIce = "user_default_ice"
    static let defaultSugar = "user_default_sugar"
    static let lastPaymentMethod = "user_last_payment"
    static let savedCards = "user_saved_cards"
    static let lastStoreId = "user_last_store"
    static let preferredStores = "user_preferred_stores"
    static let orderMethod = "user_order_method"
}

// MARK: - Models

struct SavedCard: Codable, Identifiable {
    let id: String
    let lastFour: String
    let brand: String // visa, mastercard, etc
    let expiryMonth: Int
    let expiryYear: Int
    
    var displayName: String {
        "\(brand.capitalized) •••• \(lastFour)"
    }
    
    var isExpired: Bool {
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        if let year = now.year, let month = now.month {
            if expiryYear < year { return true }
            if expiryYear == year && expiryMonth < month { return true }
        }
        return false
    }
}

enum OrderMethod: String, Codable, CaseIterable {
    case pickup = "pickup"
    case dineIn = "dine_in"
    case delivery = "delivery"
    
    var displayName: String {
        switch self {
        case .pickup: return "Pickup"
        case .dineIn: return "Dine In"
        case .delivery: return "Delivery"
        }
    }
    
    var icon: String {
        switch self {
        case .pickup: return "bag"
        case .dineIn: return "fork.knife"
        case .delivery: return "bicycle"
        }
    }
}
