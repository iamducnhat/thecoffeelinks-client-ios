//
//  PredictionModels.swift
//  thecoffeelinks-native-swift
//
//  Domain models for AI prediction engine - NO SwiftUI imports
//

import Foundation

// MARK: - Predicted Cart

// MARK: - Predicted Cart

struct PredictedCart: Identifiable, Sendable, Equatable {
    let id: UUID
    let items: [PredictedCartItem]
    let confidence: Double
    let reason: PredictionReason
    let generatedAt: Date
    
    var totalPrice: Double { items.reduce(0) { $0 + $1.totalPrice } }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
    
    var confidenceLevel: ConfidenceLevel {
        switch confidence {
        case 0.7...1.0: return .high
        case 0.4..<0.7: return .medium
        default: return .low
        }
    }
}

// MARK: - Predicted Cart Item

struct PredictedCartItem: Identifiable, Sendable, Equatable {
    let id: UUID
    let product: Product
    let customization: OrderCustomization
    let quantity: Int
    
    var unitPrice: Double {
        product.price(for: customization.size) + customization.toppingsTotal
    }
    
    var totalPrice: Double { unitPrice * Double(quantity) }
}

// MARK: - Confidence Level

enum ConfidenceLevel: Sendable, Equatable {
    case high, medium, low
    
    var displayPrefix: String {
        switch self {
        case .high: return "Your usual"
        case .medium: return "You might want"
        case .low: return "Based on your visits"
        }
    }
}

// MARK: - Prediction Reason

enum PredictionReason: Sendable, Equatable {
    case timeOfDay(TimeSlot)
    case dayOfWeek(String)
    case weather(WeatherCondition)
    case frequency
    case combo
    case custom(String)
    
    var displayText: String {
        switch self {
        case .timeOfDay(let slot): return "Your \(slot.displayName.lowercased()) go-to"
        case .dayOfWeek(let day): return "Your \(day) usual"
        case .weather(let condition): return "Perfect for \(condition.displayName.lowercased()) weather"
        case .frequency: return "Your favorite"
        case .combo: return "Your perfect combo"
        case .custom(let text): return text
        }
    }
}

// MARK: - Prediction Context

struct PredictionContext: Sendable {
    let timeSlot: TimeSlot
    let dayOfWeek: Int
    let weather: WeatherCondition?
    let location: Location?
    let currentOrderingMode: OrderingMode
    
    struct Location: Sendable {
        let latitude: Double
        let longitude: Double
        let nearestStoreId: String?
    }
    
    static var current: PredictionContext {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let dayOfWeek = calendar.component(.weekday, from: now)
        
        return PredictionContext(
            timeSlot: TimeSlot.from(hour: hour),
            dayOfWeek: dayOfWeek,
            weather: nil,
            location: nil,
            currentOrderingMode: .pickup
        )
    }
}

// MARK: - Time Slot

enum TimeSlot: String, Codable, CaseIterable, Sendable {
    case earlyMorning = "early_morning"
    case morning = "morning"
    case lunch = "lunch"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
    
    var displayName: String {
        switch self {
        case .earlyMorning: return "Early Morning"
        case .morning: return "Morning"
        case .lunch: return "Lunch"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }
    
    static func from(hour: Int) -> TimeSlot {
        switch hour {
        case 5..<8: return .earlyMorning
        case 8..<11: return .morning
        case 11..<14: return .lunch
        case 14..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
}

// MARK: - Weather Condition

enum WeatherCondition: String, Codable, CaseIterable, Sendable {
    case hot, warm, mild, cool, cold, rainy
    
    var displayName: String { rawValue.capitalized }
    var prefersHotDrinks: Bool { self == .cold || self == .cool || self == .rainy }
    var prefersColdDrinks: Bool { self == .hot || self == .warm }
}

// MARK: - Prediction History Item

struct PredictionHistoryItem: Codable, Sendable {
    let key: String
    let productId: String
    let productName: String
    let customization: OrderCustomization
    var frequency: Int
    var lastOrderedAt: Date
    var timeSlotCounts: [String: Int]
    var dayOfWeekCounts: [Int: Int]
    var weatherCounts: [String: Int]
    
    static func makeKey(productId: String, customization: OrderCustomization) -> String {
        let toppingsStr = customization.toppings.map { $0.id }.sorted().joined(separator: ",")
        return "\(productId)|\(customization.size.rawValue)|\(customization.sugar?.rawValue ?? "")|\(customization.ice?.rawValue ?? "")|\(toppingsStr)"
    }
}

// MARK: - AI Dominance Rules

struct AIDominanceRules: Sendable {
    let minOrdersForAI: Int = 5
    let minConfidence: Double = 0.4
    let highConfidence: Double = 0.7
    let hintConfidence: Double = 0.5
    let maxDismissals: Int = 3
    let dismissalWindowDays: Int = 7
    let permanentSuppressThreshold: Int = 3
    let undoWindowSeconds: TimeInterval = 30
    
    func shouldShowAICard(
        confidence: Double, orderHistory: Int, dismissedThisSession: Bool,
        cartHasItems: Bool, isUnusualTime: Bool, isSuppressed: Bool
    ) -> Bool {
        guard !dismissedThisSession else { return false }
        guard !cartHasItems else { return false }
        guard orderHistory >= minOrdersForAI else { return false }
        guard confidence >= minConfidence else { return false }
        guard !isUnusualTime else { return false }
        guard !isSuppressed else { return false }
        return true
    }
    
    func shouldShowAsHint(confidence: Double, wouldShowCard: Bool) -> Bool {
        confidence >= minConfidence && confidence < hintConfidence && !wouldShowCard
    }
}
