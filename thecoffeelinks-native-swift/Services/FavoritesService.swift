//
//  FavoritesService.swift
//  thecoffeelinks-native-swift
//
//  Manages favorites with exact configurations and notes.
//  Supports silent preference learning and auto-generated notes.
//

import Foundation
import Combine

@MainActor
class FavoritesService: ObservableObject {
    static let shared = FavoritesService()
    
    @Published var favorites: [FavoriteItem] = []
    @Published var suggestedNotes: [String: String] = [:] // productId -> suggested note
    
    private let storageKey = "user_favorites_v2"
    private let patternStorageKey = "user_order_patterns"
    private let maxFavorites = 50
    private let maxNotesPerItem = 3
    
    private init() {
        loadFromStorage()
    }
    
    // MARK: - Favorites Management
    
    /// Check if a product+customization is favorited
    func isFavorite(product: Product, customization: OrderCustomization) -> Bool {
        let key = makeMatchKey(product: product, customization: customization)
        return favorites.contains { $0.matchKey == key }
    }
    
    /// Check if a product (any customization) is favorited
    func isProductFavorited(_ product: Product) -> Bool {
        favorites.contains { $0.product.id == product.id }
    }
    
    /// Toggle favorite status
    func toggleFavorite(product: Product, customization: OrderCustomization) {
        let key = makeMatchKey(product: product, customization: customization)
        
        if let index = favorites.firstIndex(where: { $0.matchKey == key }) {
            // Remove favorite
            favorites.remove(at: index)
        } else {
            // Add favorite
            let item = FavoriteItem(product: product, customization: customization)
            favorites.insert(item, at: 0)
            
            // Limit total favorites
            if favorites.count > maxFavorites {
                favorites = Array(favorites.prefix(maxFavorites))
            }
        }
        
        saveToStorage()
    }
    
    /// Add favorite with notes
    func addFavorite(product: Product, customization: OrderCustomization, notes: [String] = []) {
        let key = makeMatchKey(product: product, customization: customization)
        
        // Don't duplicate
        guard !favorites.contains(where: { $0.matchKey == key }) else { return }
        
        var item = FavoriteItem(product: product, customization: customization)
        for noteText in notes.prefix(maxNotesPerItem) {
            item.notes.append(FavoriteNote(text: noteText))
        }
        
        favorites.insert(item, at: 0)
        saveToStorage()
    }
    
    /// Remove favorite
    func removeFavorite(_ item: FavoriteItem) {
        favorites.removeAll { $0.id == item.id }
        saveToStorage()
    }
    
    /// Get favorite for a product+customization (if exists)
    func getFavorite(product: Product, customization: OrderCustomization) -> FavoriteItem? {
        let key = makeMatchKey(product: product, customization: customization)
        return favorites.first { $0.matchKey == key }
    }
    
    /// Get all favorites for a product (any customization)
    func getFavorites(for product: Product) -> [FavoriteItem] {
        favorites.filter { $0.product.id == product.id }
    }
    
    // MARK: - Notes Management
    
    /// Add note to a favorite
    func addNote(to favoriteId: UUID, text: String) {
        guard let index = favorites.firstIndex(where: { $0.id == favoriteId }) else { return }
        guard favorites[index].notes.count < maxNotesPerItem else { return }
        
        let note = FavoriteNote(text: text)
        favorites[index].notes.append(note)
        saveToStorage()
    }
    
    /// Update note text
    func updateNote(favoriteId: UUID, noteId: UUID, text: String) {
        guard let favIndex = favorites.firstIndex(where: { $0.id == favoriteId }),
              let noteIndex = favorites[favIndex].notes.firstIndex(where: { $0.id == noteId }) else { return }
        
        favorites[favIndex].notes[noteIndex].text = String(text.prefix(140))
        saveToStorage()
    }
    
    /// Toggle note active status
    func toggleNoteActive(favoriteId: UUID, noteId: UUID) {
        guard let favIndex = favorites.firstIndex(where: { $0.id == favoriteId }),
              let noteIndex = favorites[favIndex].notes.firstIndex(where: { $0.id == noteId }) else { return }
        
        favorites[favIndex].notes[noteIndex].isActive.toggle()
        saveToStorage()
    }
    
    /// Remove note
    func removeNote(favoriteId: UUID, noteId: UUID) {
        guard let favIndex = favorites.firstIndex(where: { $0.id == favoriteId }) else { return }
        favorites[favIndex].notes.removeAll { $0.id == noteId }
        saveToStorage()
    }
    
    // MARK: - Silent Learning (Auto-Generated Notes)
    
    /// Record an order and learn patterns
    func recordOrder(items: [CartItem]) {
        var patterns = loadPatterns()
        
        for item in items {
            let productId = item.product.id
            
            // Track customization patterns
            var productPatterns = patterns[productId] ?? OrderPatterns()
            productPatterns.recordOrder(customization: item.customization)
            patterns[productId] = productPatterns
            
            // Update favorite if exists
            if let favIndex = favorites.firstIndex(where: { $0.product.id == productId && $0.matchKey == makeMatchKey(product: item.product, customization: item.customization) }) {
                favorites[favIndex].lastOrderedAt = Date()
                favorites[favIndex].orderCount += 1
            }
            
            // Generate auto-note suggestions
            generateSuggestedNote(for: productId, patterns: productPatterns)
        }
        
        savePatterns(patterns)
        saveToStorage()
    }
    
    /// Get auto-suggested customization based on patterns
    func getSuggestedCustomization(for product: Product) -> OrderCustomization? {
        let patterns = loadPatterns()
        guard let productPatterns = patterns[product.id],
              productPatterns.totalOrders >= 3 else { return nil }
        
        return productPatterns.dominantCustomization()
    }
    
    /// Check if a customization matches user's usual pattern
    func matchesUsualPattern(product: Product, customization: OrderCustomization) -> (matches: Bool, differences: [String]) {
        guard let suggested = getSuggestedCustomization(for: product) else {
            return (true, [])
        }
        
        var differences: [String] = []
        
        if customization.sugar != suggested.sugar, let sugar = suggested.sugar {
            differences.append("You usually get \(sugar) sugar")
        }
        if customization.ice != suggested.ice, let ice = suggested.ice {
            differences.append("You usually get \(ice) ice")
        }
        if customization.size != suggested.size {
            differences.append("You usually get \(suggested.size)")
        }
        
        return (differences.isEmpty, differences)
    }
    
    // MARK: - Private Methods
    
    private func makeMatchKey(product: Product, customization: OrderCustomization) -> String {
        let toppingsStr = customization.toppings?.sorted().joined(separator: ",") ?? ""
        return "\(product.id)|\(customization.size)|\(customization.sugar ?? "")|\(customization.ice ?? "")|\(toppingsStr)"
    }
    
    private func generateSuggestedNote(for productId: String, patterns: OrderPatterns) {
        guard patterns.totalOrders >= 5 else { return }
        
        // Generate note if consistent pattern detected
        if let dominantSugar = patterns.dominantSugar(), patterns.sugarConsistency > 0.8 {
            let note = "You usually reduce sugar to \(dominantSugar)"
            suggestedNotes[productId] = note
        } else if let dominantIce = patterns.dominantIce(), patterns.iceConsistency > 0.8 {
            let note = "You usually prefer \(dominantIce) ice"
            suggestedNotes[productId] = note
        }
    }
    
    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([FavoriteItem].self, from: data) else {
            return
        }
        favorites = items
    }
    
    private func saveToStorage() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadPatterns() -> [String: OrderPatterns] {
        guard let data = UserDefaults.standard.data(forKey: patternStorageKey),
              let patterns = try? JSONDecoder().decode([String: OrderPatterns].self, from: data) else {
            return [:]
        }
        return patterns
    }
    
    private func savePatterns(_ patterns: [String: OrderPatterns]) {
        if let data = try? JSONEncoder().encode(patterns) {
            UserDefaults.standard.set(data, forKey: patternStorageKey)
        }
    }
}

// MARK: - Order Patterns (for silent learning)

struct OrderPatterns: Codable {
    var totalOrders: Int = 0
    var sizeCounts: [String: Int] = [:]
    var sugarCounts: [String: Int] = [:]
    var iceCounts: [String: Int] = [:]
    
    mutating func recordOrder(customization: OrderCustomization) {
        totalOrders += 1
        sizeCounts[customization.size, default: 0] += 1
        if let sugar = customization.sugar {
            sugarCounts[sugar, default: 0] += 1
        }
        if let ice = customization.ice {
            iceCounts[ice, default: 0] += 1
        }
    }
    
    func dominantSize() -> String? {
        sizeCounts.max(by: { $0.value < $1.value })?.key
    }
    
    func dominantSugar() -> String? {
        sugarCounts.max(by: { $0.value < $1.value })?.key
    }
    
    func dominantIce() -> String? {
        iceCounts.max(by: { $0.value < $1.value })?.key
    }
    
    func dominantCustomization() -> OrderCustomization? {
        guard totalOrders >= 3 else { return nil }
        return OrderCustomization(
            size: dominantSize() ?? "M",
            ice: dominantIce(),
            sugar: dominantSugar(),
            toppings: nil
        )
    }
    
    var sugarConsistency: Double {
        guard totalOrders > 0 else { return 0 }
        let maxCount = sugarCounts.values.max() ?? 0
        return Double(maxCount) / Double(totalOrders)
    }
    
    var iceConsistency: Double {
        guard totalOrders > 0 else { return 0 }
        let maxCount = iceCounts.values.max() ?? 0
        return Double(maxCount) / Double(totalOrders)
    }
}
