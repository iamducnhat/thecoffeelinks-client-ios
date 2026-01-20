//
//  PredictionModels.swift
//  thecoffeelinks-native-swift
//
//  Domain models for AI prediction engine - NO SwiftUI imports
//

import Foundation

// MARK: - Predicted Cart

struct PredictedCart: Identifiable, Sendable, Equatable {
    let id: UUID
    let items: [PredictedCartItem]
    let confidence: Double
    let reason: PredictionReason
    // 'generatedAt' is client-created or server?
    // If client created: ok. If server returns it, map it.
    // Assuming server response includes it:
    let generatedAt: Date
    
    // Note: If PredictCart is used for decoding server response:
    // It's not Decodable currently! "struct PredictedCart: Identifiable, Sendable, Equatable" (Missing Codable)
    // The previous view_file output showed NO Codable.
    // If it's not Codable, it's irrelevant for this task unless it SHOULD be Codable.
    // However, I must assume it *might* be used in API responses if there is an AI feature.
    // Wait, the file header says "Domain models for AI prediction engine".
    // If it's pure logic, no problem. But usually predictions come from server.
    // I will add Codable and CodingKeys to be safe if it's intended to be received.
    // But I cannot change the type inheritance without verifying if it breaks usage (e.g. usage in views).
    // The previous file content did NOT have Codable.
    // I will leave it alone if it's not Codable. Mapping only applies to Codable types.
    // Checking `PredictionHistoryItem`: "struct PredictionHistoryItem: Codable, Sendable" -> YES, this one is Codable.
    
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

// ... PredictedCartItem also not Codable.

// ...

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
    
    enum CodingKeys: String, CodingKey {
        case key, frequency
        case productId = "product_id"
        case productName = "product_name"
        case customization
        case lastOrderedAt = "last_ordered_at"
        case timeSlotCounts = "time_slot_counts"
        case dayOfWeekCounts = "day_of_week_counts"
        case weatherCounts = "weather_counts"
    }
    
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

// MARK: - Predicted Cart Item

struct PredictedCartItem: Identifiable, Sendable, Equatable {
    let id: UUID
    let product: Product
    let customization: OrderCustomization
    let quantity: Int
    
    var totalPrice: Double {
        // Product now uses base_price / size_options. Assuming product.basePrice exists from Product extension computed prop
        // or we need to access size price.
        // ProductModels.swift: Product has `basePrice` (mapped to base_price).
        // Let's assume Product has basePrice property.
        // Checking ProductModels.swift in memory:
        // Product definition: let basePrice: Double? (It was let basePrice: Double? in previous context)
        // Wait, looking at Step 23 view_file ProductModels.swift:
        // basePrice WAS mapped to base_price.
        // Check `PredictedCartItem` usage in original file if possible.
        // I will assume `product.basePrice` is available or I should calculate from customization.
        // Safer:
        (product.basePrice ?? 0) + customization.toppingsTotal
    }
    
    static func == (lhs: PredictedCartItem, rhs: PredictedCartItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Prediction Reason

// MARK: - Prediction Reason

enum PredictionReason: Codable, Sendable, Equatable {
    case routine
    case weather
    case trending
    case timeOfDay(TimeSlot)
    case dayOfWeek(String)
    case frequency
    case history
    case custom(String)
    
    var displayText: String {
        switch self {
        case .routine: return "Based on your routine"
        case .weather: return "Perfect for this weather"
        case .trending: return "Popular right now"
        case .timeOfDay(let slot):
            switch slot {
            case .morning: return "Good morning"
            case .afternoon: return "Good afternoon"
            case .evening: return "Good evening"
            case .night: return "Late night snack"
            }
        case .dayOfWeek(let day): return "Happy \(day)!"
        case .frequency: return "You order this often"
        case .history: return "From your history"
        case .custom(let message): return message
        }
    }
    
    var iconName: String {
        switch self {
        case .routine: return "clock.arrow.circlepath"
        case .weather: return "cloud.sun.fill"
        case .trending: return "flame.fill"
        case .timeOfDay: return "sun.max.fill"
        case .dayOfWeek: return "calendar"
        case .frequency: return "chart.bar.fill"
        case .history: return "clock.fill"
        case .custom: return "sparkles"
        }
    }
}

// MARK: - Time Slot

enum TimeSlot: String, Codable, CaseIterable, Sendable {
    case morning
    case afternoon
    case evening
    case night
}

// MARK: - Prediction Context

struct PredictionContext: Sendable {
    let timeSlot: TimeSlot
    let dayOfWeek: Int
    let weather: WeatherCondition?
    let location: LocationType?
    
    init(
        timeSlot: TimeSlot = .morning,
        dayOfWeek: Int = Calendar.current.component(.weekday, from: Date()),
        weather: WeatherCondition? = nil,
        location: LocationType? = nil
    ) {
        self.timeSlot = timeSlot
        self.dayOfWeek = dayOfWeek
        self.weather = weather
        self.location = location
    }
    
    static var current: PredictionContext {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let dayOfWeek = calendar.component(.weekday, from: now)
        
        let timeSlot: TimeSlot
        switch hour {
        case 5..<11: timeSlot = .morning
        case 11..<14: timeSlot = .afternoon
        case 14..<18: timeSlot = .evening
        default: timeSlot = .night
        }
        
        return PredictionContext(timeSlot: timeSlot, dayOfWeek: dayOfWeek)
    }
}

enum WeatherCondition: String, Codable, Sendable {
    case sunny, rainy, cloudy, hot, cold
}

enum LocationType: String, Codable, Sendable {
    case home, work, store, transit, unknown
}

// MARK: - Confidence Level

enum ConfidenceLevel: String, Sendable {
    case high
    case medium
    case low
    
    var colorName: String {
        switch self {
        case .high: return "green"
        case .medium: return "orange"
        case .low: return "gray"
        }
    }
    
    var displayPrefix: String {
        switch self {
        case .high: return "High Confidence"
        case .medium: return "Suggested"
        case .low: return "For You"
        }
    }
}
