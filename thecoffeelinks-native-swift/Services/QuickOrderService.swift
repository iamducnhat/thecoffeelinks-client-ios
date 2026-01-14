//
//  QuickOrderService.swift
//  thecoffeelinks-native-swift
//
//  Quick Order Engine - "Your Usual" algorithm
//  Tracks user ordering patterns and provides 1-tap reorder.
//

import Foundation
import Combine

// MARK: - Quick Order Models

struct QuickOrderItem: Identifiable, Codable {
    let id: UUID
    let product: Product
    let customization: OrderCustomization
    let frequency: Int // Number of times ordered
    let lastOrdered: Date
    
    var displayName: String {
        var name = product.name
        if customization.size != "M" && customization.size != "Medium" {
            name += " (\(customization.size))"
        }
        return name
    }
    
    var priceForSize: Double {
        guard let options = product.sizeOptions else { return 0 }
        
        switch customization.size.lowercased() {
        case "s", "small":
            return options.small.price
        case "m", "medium":
            return options.medium.price
        case "l", "large":
            return options.large.price
        default:
            return options.medium.price // Default to medium
        }
    }
}

// MARK: - Quick Order Service

@MainActor
class QuickOrderService: ObservableObject {
    static let shared = QuickOrderService()
    
    @Published var yourUsuals: [QuickOrderItem] = []
    @Published var isLoading = false
    
    private let storageKey = "quick_order_history"
    private let maxUsuals = 3 // Show max 3 items in widget
    
    private init() {
        loadFromStorage()
    }
    
    // MARK: - Public API
    
    /// Record an order to build "Your Usual" history
    func recordOrder(items: [CartItem]) {
        var history = loadHistory()
        
        for item in items {
            let key = makeKey(product: item.product, customization: item.customization)
            
            if let existingIndex = history.firstIndex(where: { makeKey(product: $0.product, customization: $0.customization) == key }) {
                // Update existing entry
                var existing = history[existingIndex]
                existing = QuickOrderItem(
                    id: existing.id,
                    product: existing.product,
                    customization: existing.customization,
                    frequency: existing.frequency + item.quantity,
                    lastOrdered: Date()
                )
                history[existingIndex] = existing
            } else {
                // Add new entry
                let newItem = QuickOrderItem(
                    id: UUID(),
                    product: item.product,
                    customization: item.customization,
                    frequency: item.quantity,
                    lastOrdered: Date()
                )
                history.append(newItem)
            }
        }
        
        saveHistory(history)
        updateYourUsuals()
    }
    
    /// Get "Your Usual" items sorted by frequency + recency
    func getYourUsuals() -> [QuickOrderItem] {
        return yourUsuals
    }
    
    /// Instant reorder - adds to cart and returns true if successful
    func quickReorder(item: QuickOrderItem) -> Bool {
        let cartManager = CartManager.shared
        
        cartManager.addToCart(
            product: item.product,
            quantity: 1,
            finalPrice: item.priceForSize,
            customization: item.customization
        )
        
        // Record this reorder
        recordOrder(items: [CartItem(
            id: UUID(),
            product: item.product,
            quantity: 1,
            finalPrice: item.priceForSize,
            customization: item.customization
        )])
        
        return true
    }
    
    /// Quick checkout - 1-tap order with saved settings
    func quickCheckout(item: QuickOrderItem) async -> Bool {
        let cartManager = CartManager.shared
        
        // Clear cart and add this item
        cartManager.clearCart()
        
        cartManager.addToCart(
            product: item.product,
            quantity: 1,
            finalPrice: item.priceForSize,
            customization: item.customization
        )
        
        // Auto-select nearest store if not set
        if cartManager.selectedStoreId == nil {
            await autoSelectNearestStore()
        }
        
        // Place order
        let success = await cartManager.placeOrder()
        
        if success {
            // Record this order
            recordOrder(items: cartManager.items)
        }
        
        return success
    }
    
    // MARK: - Time-based Suggestions
    
    var morningUsual: QuickOrderItem? {
        // Return most frequent morning order (before 11 AM)
        yourUsuals.first
    }
    
    var afternoonUsual: QuickOrderItem? {
        // Could have time-based logic, for now return second most frequent
        yourUsuals.count > 1 ? yourUsuals[1] : yourUsuals.first
    }
    
    // MARK: - Private Methods
    
    private func makeKey(product: Product, customization: OrderCustomization) -> String {
        // Create unique key based on product + customization
        let toppingsStr = customization.toppings?.sorted().joined(separator: ",") ?? ""
        return "\(product.id)|\(customization.size)|\(customization.sugar ?? "")|\(customization.ice ?? "")|\(toppingsStr)"
    }
    
    private func loadFromStorage() {
        updateYourUsuals()
    }
    
    private func loadHistory() -> [QuickOrderItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let history = try? JSONDecoder().decode([QuickOrderItem].self, from: data) else {
            return []
        }
        return history
    }
    
    private func saveHistory(_ history: [QuickOrderItem]) {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func updateYourUsuals() {
        let history = loadHistory()
        
        // Score = frequency * recencyWeight
        // Recency weight: 1.0 for today, 0.9 for yesterday, etc.
        let now = Date()
        
        let scored = history.map { item -> (QuickOrderItem, Double) in
            let daysSinceOrder = Calendar.current.dateComponents([.day], from: item.lastOrdered, to: now).day ?? 0
            let recencyWeight = max(0.5, 1.0 - (Double(daysSinceOrder) * 0.1))
            let score = Double(item.frequency) * recencyWeight
            return (item, score)
        }
        
        // Sort by score descending, take top 3
        let sorted = scored.sorted { $0.1 > $1.1 }
        yourUsuals = Array(sorted.prefix(maxUsuals).map { $0.0 })
    }
    
    private func autoSelectNearestStore() async {
        // TODO: Integrate with LocationManager to get nearest store
        // For now, use first cached store
        if let cachedStores = CacheManager.shared.load([Store].self, for: "stores_cache"),
           let firstStore = cachedStores.first {
            CartManager.shared.selectedStoreId = firstStore.id
        }
    }
}

// MARK: - Streak Tracking

extension QuickOrderService {
    private var streakKey: String { "order_streak" }
    private var lastOrderDateKey: String { "last_order_date" }
    
    var currentStreak: Int {
        UserDefaults.standard.integer(forKey: streakKey)
    }
    
    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastOrderDateData = UserDefaults.standard.object(forKey: lastOrderDateKey) as? Date {
            let lastOrderDay = calendar.startOfDay(for: lastOrderDateData)
            let daysDiff = calendar.dateComponents([.day], from: lastOrderDay, to: today).day ?? 0
            
            if daysDiff == 0 {
                // Same day, no streak change
                return
            } else if daysDiff == 1 {
                // Consecutive day, increment streak
                let newStreak = currentStreak + 1
                UserDefaults.standard.set(newStreak, forKey: streakKey)
            } else {
                // Streak broken, reset to 1
                UserDefaults.standard.set(1, forKey: streakKey)
            }
        } else {
            // First order ever
            UserDefaults.standard.set(1, forKey: streakKey)
        }
        
        // Update last order date
        UserDefaults.standard.set(today, forKey: lastOrderDateKey)
    }
    
    var isStreakAtRisk: Bool {
        guard let lastOrderDate = UserDefaults.standard.object(forKey: lastOrderDateKey) as? Date else {
            return false
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastOrderDay = calendar.startOfDay(for: lastOrderDate)
        let daysDiff = calendar.dateComponents([.day], from: lastOrderDay, to: today).day ?? 0
        
        return daysDiff >= 1 && currentStreak > 0
    }
}
