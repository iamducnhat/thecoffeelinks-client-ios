//
//  StoreScoreCalculator.swift
//  TheCoffeeLinks
//
//  Created on 2026-02-03.
//

import Foundation
import CoreLocation

// MARK: - Store Score Model

/// Represents a scored store with reasoning for multi-store delivery selection
struct StoreScore: Identifiable, Comparable {
    let id: String
    let store: Store
    let availability: DeliveryAvailability
    let distance: Double // in kilometers
    let score: Double // 0-100, higher is better
    let availableItemsCount: Int
    let unavailableItemsCount: Int
    let reasons: [ScoreReason]
    let isPrimary: Bool // True if this is the recommended store
    
    var totalItemsCount: Int {
        availableItemsCount + unavailableItemsCount
    }
    
    var availabilityPercentage: Double {
        guard totalItemsCount > 0 else { return 100.0 }
        return Double(availableItemsCount) / Double(totalItemsCount) * 100.0
    }
    
    var displayReason: String {
        if reasons.isEmpty {
            return "Available"
        }
        return reasons.map { $0.displayText }.joined(separator: " • ")
    }
    
    // Comparable conformance for sorting
    static func < (lhs: StoreScore, rhs: StoreScore) -> Bool {
        lhs.score < rhs.score
    }
    
    static func == (lhs: StoreScore, rhs: StoreScore) -> Bool {
        lhs.id == rhs.id
    }
}

/// Reasons why a store scored well
enum ScoreReason: Equatable {
    case bestAvailability
    case fullAvailability
    case cheapest
    case fastest
    case closest
    case recommended
    
    var displayText: String {
        switch self {
        case .bestAvailability: return "Best Availability"
        case .fullAvailability: return "All Items Available"
        case .cheapest: return "Lowest Fee"
        case .fastest: return "Fastest Delivery"
        case .closest: return "Nearest"
        case .recommended: return "Recommended"
        }
    }
    
    var emoji: String {
        switch self {
        case .bestAvailability: return "✓"
        case .fullAvailability: return "✓"
        case .cheapest: return "💰"
        case .fastest: return "⚡"
        case .closest: return "📍"
        case .recommended: return "⭐"
        }
    }
}

// MARK: - Store Score Calculator

/// Calculates optimal store selection based on cart contents, delivery fees, and ETAs
@MainActor
final class StoreScoreCalculator {
    
    // MARK: - Scoring Weights
    
    /// Weight distribution for scoring algorithm (must sum to 1.0)
    struct ScoringWeights {
        let availability: Double = 0.50  // 50% - Most important
        let deliveryFee: Double = 0.30   // 30% - Price matters
        let estimatedTime: Double = 0.20 // 20% - Speed bonus
        
        static let `default` = ScoringWeights()
    }
    
    private let weights: ScoringWeights
    
    init(weights: ScoringWeights = .default) {
        self.weights = weights
    }
    
    // MARK: - Public API
    
    /// Calculate scores for multiple stores based on cart items
    /// - Parameters:
    ///   - stores: Candidate stores to score
    ///   - availabilities: Delivery availability data per store
    ///   - cartItems: Current cart items to check availability
    ///   - userLocation: User's delivery address coordinates (optional)
    /// - Returns: Array of scored stores, sorted by score (best first)
    func calculateScores(
        stores: [Store],
        availabilities: [String: DeliveryAvailability], // keyed by storeId
        cartItems: [CartItem],
        userLocation: CLLocationCoordinate2D?
    ) -> [StoreScore] {
        
        guard !stores.isEmpty else { return [] }
        
        var scores: [StoreScore] = []
        
        for store in stores {
            guard let availability = availabilities[store.id],
                  availability.available else {
                continue // Skip unavailable stores
            }
            
            // Calculate distance if user location provided
            let distance = calculateDistance(
                from: userLocation,
                to: CLLocationCoordinate2D(
                    latitude: store.latitude,
                    longitude: store.longitude
                )
            )
            
            // Calculate component scores
            let availabilityScore = calculateAvailabilityScore(
                store: store,
                cartItems: cartItems
            )
            
            let feeScore = calculateFeeScore(
                availability: availability,
                allAvailabilities: Array(availabilities.values)
            )
            
            let timeScore = calculateTimeScore(
                availability: availability,
                allAvailabilities: Array(availabilities.values)
            )
            
            // Weighted total score (0-100)
            let totalScore = (
                availabilityScore.score * weights.availability +
                feeScore * weights.deliveryFee +
                timeScore * weights.estimatedTime
            ) * 100.0
            
            // Determine reasons
            var reasons: [ScoreReason] = []
            if availabilityScore.unavailableCount == 0 {
                reasons.append(.fullAvailability)
            } else if availabilityScore.availableCount > 0 {
                reasons.append(.bestAvailability)
            }
            
            let storeScore = StoreScore(
                id: store.id,
                store: store,
                availability: availability,
                distance: distance,
                score: totalScore,
                availableItemsCount: availabilityScore.availableCount,
                unavailableItemsCount: availabilityScore.unavailableCount,
                reasons: reasons,
                isPrimary: false // Will be set after sorting
            )
            
            scores.append(storeScore)
        }
        
        // Sort by score (highest first)
        scores.sort(by: >)
        
        // Add comparative reasons to top stores
        scores = addComparativeReasons(to: scores, availabilities: availabilities)
        
        // Mark the best store as primary
        if !scores.isEmpty {
            scores[0] = StoreScore(
                id: scores[0].id,
                store: scores[0].store,
                availability: scores[0].availability,
                distance: scores[0].distance,
                score: scores[0].score,
                availableItemsCount: scores[0].availableItemsCount,
                unavailableItemsCount: scores[0].unavailableItemsCount,
                reasons: [.recommended] + scores[0].reasons,
                isPrimary: true
            )
        }
        
        return scores
    }
    
    /// Quick recommendation - returns just the best store
    func recommendBestStore(
        stores: [Store],
        availabilities: [String: DeliveryAvailability],
        cartItems: [CartItem],
        userLocation: CLLocationCoordinate2D?
    ) -> StoreScore? {
        let scores = calculateScores(
            stores: stores,
            availabilities: availabilities,
            cartItems: cartItems,
            userLocation: userLocation
        )
        return scores.first
    }
    
    // MARK: - Scoring Components
    
    /// Calculate availability score based on cart items
    private func calculateAvailabilityScore(
        store: Store,
        cartItems: [CartItem]
    ) -> (score: Double, availableCount: Int, unavailableCount: Int) {
        
        guard !cartItems.isEmpty else {
            return (score: 1.0, availableCount: 0, unavailableCount: 0)
        }
        
        var availableCount = 0
        var unavailableCount = 0
        
        for item in cartItems {
            // Check if product is deliverable and store has delivery
            let isAvailable = item.product.isDeliverable && store.deliveryAvailable == true
            
            // TODO: In future, check store-specific product availability
            // from store_product_availability table when backend API supports it
            
            if isAvailable {
                availableCount += item.quantity
            } else {
                unavailableCount += item.quantity
            }
        }
        
        let totalItems = availableCount + unavailableCount
        let score = totalItems > 0 ? Double(availableCount) / Double(totalItems) : 1.0
        
        return (score: score, availableCount: availableCount, unavailableCount: unavailableCount)
    }
    
    /// Calculate fee score (lower fee = higher score)
    private func calculateFeeScore(
        availability: DeliveryAvailability,
        allAvailabilities: [DeliveryAvailability]
    ) -> Double {
        
        guard let fee = availability.fee?.amount,
              fee > 0 else {
            return 1.0 // Free delivery gets max score
        }
        
        // Find min and max fees
        let fees = allAvailabilities.compactMap { $0.fee?.amount }.filter { $0 > 0 }
        guard !fees.isEmpty else { return 1.0 }
        
        let minFee = fees.min() ?? fee
        let maxFee = fees.max() ?? fee
        
        // Normalize: lower fee gets higher score
        if maxFee == minFee {
            return 1.0
        }
        
        return 1.0 - ((fee - minFee) / (maxFee - minFee))
    }
    
    /// Calculate time score (shorter ETA = higher score)
    private func calculateTimeScore(
        availability: DeliveryAvailability,
        allAvailabilities: [DeliveryAvailability]
    ) -> Double {
        
        guard let eta = availability.eta?.minutes,
              eta > 0 else {
            return 0.5 // Unknown ETA gets neutral score
        }
        
        // Find min and max ETAs
        let etas = allAvailabilities.compactMap { $0.eta?.minutes }.filter { $0 > 0 }
        guard !etas.isEmpty else { return 1.0 }
        
        let minEta = etas.min() ?? eta
        let maxEta = etas.max() ?? eta
        
        // Normalize: shorter time gets higher score
        if maxEta == minEta {
            return 1.0
        }
        
        return 1.0 - ((Double(eta) - Double(minEta)) / (Double(maxEta) - Double(minEta)))
    }
    
    /// Calculate distance between two coordinates
    private func calculateDistance(
        from: CLLocationCoordinate2D?,
        to: CLLocationCoordinate2D
    ) -> Double {
        guard let from = from else { return 0.0 }
        
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        
        // Return distance in kilometers
        return fromLocation.distance(from: toLocation) / 1000.0
    }
    
    /// Add comparative reasons (cheapest, fastest, closest) to top stores
    private func addComparativeReasons(
        to scores: [StoreScore],
        availabilities: [String: DeliveryAvailability]
    ) -> [StoreScore] {
        
        guard !scores.isEmpty else { return scores }
        
        // Find stores with best metrics
        let cheapestStore = scores.min(by: { ($0.availability.fee?.amount ?? Double.infinity) < ($1.availability.fee?.amount ?? Double.infinity) })
        let fastestStore = scores.min(by: { ($0.availability.eta?.minutes ?? Int.max) < ($1.availability.eta?.minutes ?? Int.max) })
        let closestStore = scores.min(by: { $0.distance < $1.distance })
        
        var updatedScores: [StoreScore] = []
        
        for score in scores {
            var newReasons = score.reasons
            
            if score.id == cheapestStore?.id {
                newReasons.insert(.cheapest, at: 0)
            }
            if score.id == fastestStore?.id {
                newReasons.insert(.fastest, at: 0)
            }
            if score.id == closestStore?.id && score.distance > 0 {
                newReasons.append(.closest)
            }
            
            updatedScores.append(
                StoreScore(
                    id: score.id,
                    store: score.store,
                    availability: score.availability,
                    distance: score.distance,
                    score: score.score,
                    availableItemsCount: score.availableItemsCount,
                    unavailableItemsCount: score.unavailableItemsCount,
                    reasons: newReasons,
                    isPrimary: score.isPrimary
                )
            )
        }
        
        return updatedScores
    }
}
