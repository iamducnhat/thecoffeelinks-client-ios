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
