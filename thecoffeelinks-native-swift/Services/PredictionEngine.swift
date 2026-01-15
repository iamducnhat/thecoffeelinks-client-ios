//
//  PredictionEngine.swift
//  thecoffeelinks-native-swift
//
//  AI prediction engine for Ready-to-Order carts.
//  Uses frequency × recency × time × weather × day-of-week scoring.
//

import Foundation
import Combine

@MainActor
class PredictionEngine: ObservableObject {
    static let shared = PredictionEngine()
    
    @Published var readyToOrderCart: PredictedCart?
    @Published var confidence: Double = 0
    @Published var isLoading = false
    
    // AI DOMINANCE RULES
    // When AI card should be visible vs hidden
    @Published var isDismissedThisSession = false
    
    private let storageKey = "prediction_history"
    private let dismissalKey = "prediction_dismissals"
    private let permanentSuppressKey = "prediction_permanent_suppress"
    
    // Confidence thresholds
    private let highConfidence: Double = 0.7  // "Your usual" language
    private let mediumConfidence: Double = 0.4 // "You might want" language
    private let minConfidence: Double = 0.4   // Below this = no AI card
    private let hintConfidence: Double = 0.5  // Show as hint, not card
    
    private let maxDismissals = 3
    private let minOrdersForAI = 5 // User must have 5+ orders for AI
    
    private init() {}
    
    // MARK: - Public API
    
    /// Generate AI-predicted cart for the current context
    func generatePrediction() async {
        isLoading = true
        defer { isLoading = false }
        
        // Check if user has dismissed too many times recently
        guard !shouldHidePredictions() else {
            readyToOrderCart = nil
            return
        }
        
        let context = PredictionContext()
        let history = loadHistory()
        
        guard !history.isEmpty else {
            readyToOrderCart = nil
            return
        }
        
        // Score all historical items
        var scoredItems: [(PredictionHistoryItem, Double)] = []
        
        for item in history {
            let score = calculateScore(item: item, context: context)
            scoredItems.append((item, score))
        }
        
        // Sort by score
        scoredItems.sort { $0.1 > $1.1 }
        
        // Take top item(s) for cart
        guard let topItem = scoredItems.first, topItem.1 >= minConfidence else {
            readyToOrderCart = nil
            confidence = 0
            return
        }
        
        // Check if user typically orders multiple items together
        var cartItems: [PredictedCartItem] = []
        cartItems.append(toPredictedCartItem(topItem.0))
        
        // Add combo item if pattern detected (e.g., coffee + pastry)
        if let comboItem = findComboItem(for: topItem.0, in: scoredItems) {
            cartItems.append(toPredictedCartItem(comboItem))
        }
        
        confidence = topItem.1
        readyToOrderCart = PredictedCart(
            items: cartItems,
            confidence: confidence,
            reason: generateReason(context: context, topItem: topItem.0),
            generatedAt: Date()
        )
    }
    
    /// Record that user ordered these items
    func recordOrder(items: [CartItem], context: PredictionContext) {
        var history = loadHistory()
        
        for item in items {
            let key = makeKey(product: item.product, customization: item.customization)
            
            if let index = history.firstIndex(where: { $0.key == key }) {
                // Update existing
                history[index].frequency += item.quantity
                history[index].lastOrderedAt = Date()
                history[index].timeSlotCounts[context.timeSlot.rawValue, default: 0] += 1
                history[index].dayOfWeekCounts[context.dayOfWeek, default: 0] += 1
                history[index].weatherCounts[context.weather?.rawValue ?? "normal", default: 0] += 1
            } else {
                // Create new
                var newItem = PredictionHistoryItem(
                    key: key,
                    product: item.product,
                    customization: item.customization
                )
                newItem.frequency = item.quantity
                newItem.lastOrderedAt = Date()
                newItem.timeSlotCounts[context.timeSlot.rawValue] = 1
                newItem.dayOfWeekCounts[context.dayOfWeek] = 1
                newItem.weatherCounts[context.weather?.rawValue ?? "normal"] = 1
                history.append(newItem)
            }
        }
        
        saveHistory(history)
        
        // Record successful prediction if applicable
        if let cart = readyToOrderCart {
            recordPredictionResult(wasAccepted: true, cart: cart)
        }
        
        // Clear dismissal count on successful order
        clearDismissals()
    }
    
    /// User dismissed the prediction
    func dismissPrediction() {
        isDismissedThisSession = true
        recordDismissal()
        
        // Track permanent suppression for specific combos
        if let cart = readyToOrderCart {
            recordDismissalForCombo(cart: cart)
        }
        
        readyToOrderCart = nil
    }
    
    /// User accepted prediction (for analytics)
    func acceptPrediction() {
        if let cart = readyToOrderCart {
            recordPredictionResult(wasAccepted: true, cart: cart)
        }
        // Clear session dismissal on acceptance
        isDismissedThisSession = false
    }
    
    /// Reset session state (call on app foreground)
    func resetSession() {
        isDismissedThisSession = false
    }
    
    // MARK: - AI DOMINANCE RULES (PUBLIC)
    
    /// Should the AI card take over Home (be the FIRST element)?
    var shouldShowAICard: Bool {
        // Rule 1: User dismissed this session → NO
        guard !isDismissedThisSession else { return false }
        
        // Rule 2: Cart already has items → NO (don't interrupt)
        guard CartManager.shared.items.isEmpty else { return false }
        
        // Rule 3: Not enough history → NO
        guard loadHistory().count >= minOrdersForAI else { return false }
        
        // Rule 4: Confidence too low → NO
        guard confidence >= minConfidence else { return false }
        
        // Rule 5: Prediction exists
        guard readyToOrderCart != nil else { return false }
        
        // Rule 6: User ordering at unusual time → NO (let them explore)
        guard !isUnusualTimeSlot() else { return false }
        
        // Rule 7: Specific combo permanently suppressed → NO
        guard !isCurrentPredictionSuppressed() else { return false }
        
        return true
    }
    
    /// Should AI show as smaller hint instead of full card?
    var shouldShowAsHint: Bool {
        return confidence >= minConfidence && confidence < hintConfidence && !shouldShowAICard
    }
    
    /// Get appropriate language for current confidence
    var predictionLanguage: String {
        if confidence >= highConfidence {
            return "Your usual"
        } else if confidence >= mediumConfidence {
            return "You might want"
        } else {
            return "Based on your visits"
        }
    }
    
    /// When AI should completely shut up
    var shouldShutUp: Bool {
        return shouldHidePredictions() || loadHistory().isEmpty
    }
    
    /// Get prediction for a specific time (for scheduling)
    func getPredictionFor(timeSlot: TimeSlot, dayOfWeek: Int) -> PredictedCart? {
        let history = loadHistory()
        
        var bestItem: PredictionHistoryItem?
        var bestScore: Double = 0
        
        for item in history {
            let timeScore = Double(item.timeSlotCounts[timeSlot.rawValue] ?? 0) / Double(max(item.frequency, 1))
            let dayScore = Double(item.dayOfWeekCounts[dayOfWeek] ?? 0) / Double(max(item.frequency, 1))
            let score = (timeScore * 0.6) + (dayScore * 0.4)
            
            if score > bestScore {
                bestScore = score
                bestItem = item
            }
        }
        
        guard let item = bestItem, bestScore >= 0.3 else { return nil }
        
        return PredictedCart(
            items: [toPredictedCartItem(item)],
            confidence: bestScore,
            reason: "Your usual for \(timeSlot.rawValue)",
            generatedAt: Date()
        )
    }
    
    // MARK: - Scoring Algorithm
    
    private func calculateScore(item: PredictionHistoryItem, context: PredictionContext) -> Double {
        var score: Double = 0
        
        // Base: Frequency (capped at 30 to prevent runaway dominance)
        let frequencyScore = min(Double(item.frequency), 30) / 30.0
        score += frequencyScore * 0.3
        
        // Recency: Days since last order
        let daysSince = Calendar.current.dateComponents([.day], from: item.lastOrderedAt, to: Date()).day ?? 365
        let recencyScore = max(0, 1.0 - (Double(daysSince) / 30.0))
        score += recencyScore * 0.2
        
        // Time slot match
        let timeSlotOrders = item.timeSlotCounts[context.timeSlot.rawValue] ?? 0
        let timeScore = min(Double(timeSlotOrders), 10) / 10.0
        score += timeScore * 0.25
        
        // Day of week match
        let dayOrders = item.dayOfWeekCounts[context.dayOfWeek] ?? 0
        let dayScore = min(Double(dayOrders), 5) / 5.0
        score += dayScore * 0.15
        
        // Weather match (if available)
        if let weather = context.weather {
            let weatherOrders = item.weatherCounts[weather.rawValue] ?? 0
            let weatherScore = min(Double(weatherOrders), 5) / 5.0
            score += weatherScore * 0.1
            
            // Bonus for weather-appropriate drinks
            if weather.prefersHotDrinks && item.customization.ice == "no" {
                score += 0.05
            } else if weather.prefersColdDrinks && item.customization.ice != "no" {
                score += 0.05
            }
        }
        
        return min(score, 1.0)
    }
    
    private func findComboItem(for primary: PredictionHistoryItem, in scored: [(PredictionHistoryItem, Double)]) -> PredictionHistoryItem? {
        // Look for items frequently ordered together
        // Simple heuristic: if pastry ordered >50% of times with coffee
        // TODO: Implement proper co-occurrence tracking
        
        for (item, score) in scored where score > 0.4 {
            if item.key != primary.key {
                // Check if different category (e.g., coffee + pastry)
                if item.product.category != primary.product.category {
                    return item
                }
            }
        }
        return nil
    }
    
    private func generateReason(context: PredictionContext, topItem: PredictionHistoryItem) -> String {
        let timeSlotOrders = topItem.timeSlotCounts[context.timeSlot.rawValue] ?? 0
        let dayOrders = topItem.dayOfWeekCounts[context.dayOfWeek] ?? 0
        
        if timeSlotOrders >= 5 && dayOrders >= 3 {
            return "Your \(context.timeSlot.rawValue) ritual"
        } else if timeSlotOrders >= 5 {
            return "Your \(context.timeSlot.rawValue) go-to"
        } else if dayOrders >= 3 {
            let dayName = Calendar.current.weekdaySymbols[context.dayOfWeek - 1]
            return "Your \(dayName) usual"
        } else if topItem.frequency >= 10 {
            return "Your favorite"
        } else {
            return "Based on your history"
        }
    }
    
    private func toPredictedCartItem(_ item: PredictionHistoryItem) -> PredictedCartItem {
        PredictedCartItem(
            product: item.product,
            customization: item.customization,
            quantity: 1
        )
    }
    
    // MARK: - Dismissal Tracking
    
    private func shouldHidePredictions() -> Bool {
        let dismissals = loadDismissals()
        // Hide if dismissed 3x in the last 7 days
        let recentDismissals = dismissals.filter {
            Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 365 < 7
        }
        return recentDismissals.count >= maxDismissals
    }
    
    private func recordDismissal() {
        var dismissals = loadDismissals()
        dismissals.append(Date())
        // Keep only last 10
        if dismissals.count > 10 {
            dismissals = Array(dismissals.suffix(10))
        }
        if let data = try? JSONEncoder().encode(dismissals) {
            UserDefaults.standard.set(data, forKey: dismissalKey)
        }
    }
    
    private func clearDismissals() {
        UserDefaults.standard.removeObject(forKey: dismissalKey)
    }
    
    private func loadDismissals() -> [Date] {
        guard let data = UserDefaults.standard.data(forKey: dismissalKey),
              let dates = try? JSONDecoder().decode([Date].self, from: data) else {
            return []
        }
        return dates
    }
    
    private func recordPredictionResult(wasAccepted: Bool, cart: PredictedCart) {
        // TODO: Analytics tracking
    }
    
    // MARK: - AI Dominance Helpers
    
    /// Check if user is ordering at an unusual time (no history for this slot)
    private func isUnusualTimeSlot() -> Bool {
        let context = PredictionContext()
        let history = loadHistory()
        
        // Count orders in current time slot
        let slotCount = history.reduce(0) { sum, item in
            sum + (item.timeSlotCounts[context.timeSlot.rawValue] ?? 0)
        }
        
        // If less than 2 orders in this time slot ever, it's unusual
        return slotCount < 2
    }
    
    /// Check if current prediction combo is permanently suppressed
    private func isCurrentPredictionSuppressed() -> Bool {
        guard let cart = readyToOrderCart else { return false }
        
        let suppressed = loadSuppressedCombos()
        let currentKey = cart.items.map { $0.product.id }.sorted().joined(separator: "|")
        
        return suppressed.contains(currentKey)
    }
    
    /// Record dismissal for specific combo (3x = permanent suppress)
    private func recordDismissalForCombo(cart: PredictedCart) {
        let key = cart.items.map { $0.product.id }.sorted().joined(separator: "|")
        var comboDismissals = loadComboDismissals()
        
        comboDismissals[key, default: 0] += 1
        
        // If dismissed 3x, add to permanent suppress list
        if comboDismissals[key, default: 0] >= 3 {
            var suppressed = loadSuppressedCombos()
            suppressed.insert(key)
            saveSuppressedCombos(suppressed)
        }
        
        saveComboDismissals(comboDismissals)
    }
    
    private func loadComboDismissals() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: "\(dismissalKey)_combos"),
              let counts = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return counts
    }
    
    private func saveComboDismissals(_ counts: [String: Int]) {
        if let data = try? JSONEncoder().encode(counts) {
            UserDefaults.standard.set(data, forKey: "\(dismissalKey)_combos")
        }
    }
    
    private func loadSuppressedCombos() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: permanentSuppressKey),
              let list = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(list)
    }
    
    private func saveSuppressedCombos(_ set: Set<String>) {
        if let data = try? JSONEncoder().encode(Array(set)) {
            UserDefaults.standard.set(data, forKey: permanentSuppressKey)
        }
    }
    
    // MARK: - Storage
    
    private func makeKey(product: Product, customization: OrderCustomization) -> String {
        let toppingsStr = customization.toppings?.sorted().joined(separator: ",") ?? ""
        return "\(product.id)|\(customization.size)|\(customization.sugar ?? "")|\(customization.ice ?? "")|\(toppingsStr)"
    }
    
    private func loadHistory() -> [PredictionHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([PredictionHistoryItem].self, from: data) else {
            return []
        }
        return items
    }
    
    private func saveHistory(_ history: [PredictionHistoryItem]) {
        // Keep max 100 items
        let trimmed = Array(history.suffix(100))
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

// MARK: - Models

struct PredictionHistoryItem: Codable {
    let key: String
    let product: Product
    let customization: OrderCustomization
    var frequency: Int = 0
    var lastOrderedAt: Date = Date()
    var timeSlotCounts: [String: Int] = [:] // morning/afternoon/evening -> count
    var dayOfWeekCounts: [Int: Int] = [:] // 1-7 -> count
    var weatherCounts: [String: Int] = [:] // hot/cold/rainy/normal -> count
}

struct PredictedCart: Identifiable {
    let id = UUID()
    let items: [PredictedCartItem]
    let confidence: Double // 0-1
    let reason: String
    let generatedAt: Date
    
    var totalPrice: Double {
        items.reduce(0) { $0 + $1.price }
    }
    
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
}

struct PredictedCartItem: Identifiable {
    let id = UUID()
    let product: Product
    let customization: OrderCustomization
    let quantity: Int
    
    var price: Double {
        guard let options = product.sizeOptions else { return 0 }
        switch customization.size.lowercased() {
        case "s", "small": return options.small.price * Double(quantity)
        case "m", "medium": return options.medium.price * Double(quantity)
        case "l", "large": return options.large.price * Double(quantity)
        default: return options.medium.price * Double(quantity)
        }
    }
}
