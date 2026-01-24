//
//  EnhancedPredictionEngine.swift
//  thecoffeelinks-client-ios
//
//  Enhanced AI prediction with time/weather patterns and confidence scoring
//

import Foundation

final class EnhancedPredictionEngine: Sendable {
    private let repository: PredictionRepositoryProtocol
    
    // Confidence thresholds
    private let minConfidence: Double = 0.6 // Must be 60%+ to show
    private let highConfidence: Double = 0.8 // 80%+ is high confidence
    
    init(repository: PredictionRepositoryProtocol) {
        self.repository = repository
    }
    
    func generatePrediction(context: PredictionContext) async -> PredictedCart? {
        let history = await repository.getHistory()
        guard !history.isEmpty else { return nil }
        
        let suppressed = await repository.getSuppressedCombos()
        let recentDismissals = await repository.getDismissals().filter { Date().timeIntervalSince($0) < 86400 * 7 }
        
        // Too many recent dismissals = user doesn't want predictions
        if recentDismissals.count >= 3 { return nil }
        
        // Score each item based on multiple factors
        var scoredItems: [(item: PredictionHistoryItem, score: Double, confidence: Double)] = []
        
        for item in history {
            guard !suppressed.contains(item.key) else { continue }
            
            let score = calculateScore(item: item, context: context)
            let confidence = calculateConfidence(item: item, context: context)
            
            // Filter by minimum confidence
            if confidence >= minConfidence {
                scoredItems.append((item, score, confidence))
            }
        }
        
        // Sort by score
        scoredItems.sort { $0.score > $1.score }
        
        guard let best = scoredItems.first else { return nil }
        
        // Note: Requires MenuRepository to lookup full Product by productId
        // This is intentionally incomplete - predictions shown at HomeView level instead
        // where full product context is available. Engine focuses on scoring/confidence.
        _ = generateExplanation(item: best.item, context: context, confidence: best.confidence)
        return nil
    }
    
    private func calculateScore(item: PredictionHistoryItem, context: PredictionContext) -> Double {
        var score: Double = 0.0
        
        // Base frequency (normalized)
        score += min(Double(item.frequency) / 10.0, 5.0) * 10.0
        
        // Recency boost (orders in last 7 days get bonus)
        let daysSince = Calendar.current.dateComponents([.day], from: item.lastOrderedAt, to: Date()).day ?? 999
        if daysSince <= 7 {
            score += (7.0 - Double(daysSince)) * 5.0
        }
        
        // Time-of-day pattern match
        let timeSlotCount = item.timeSlotCounts[context.timeSlot.rawValue] ?? 0
        let totalOrders = item.timeSlotCounts.values.reduce(0, +)
        if totalOrders > 0 {
            let timeSlotRatio = Double(timeSlotCount) / Double(totalOrders)
            score += timeSlotRatio * 30.0 // Strong weight for time patterns
        }
        
        // Day-of-week pattern match
        let dowCount = item.dayOfWeekCounts[context.dayOfWeek] ?? 0
        let totalDowOrders = item.dayOfWeekCounts.values.reduce(0, +)
        if totalDowOrders > 0 {
            let dowRatio = Double(dowCount) / Double(totalDowOrders)
            score += dowRatio * 20.0
        }
        
        // Weather pattern match (if available)
        if let weather = context.weather {
            let weatherCount = item.weatherCounts[weather.rawValue] ?? 0
            let totalWeatherOrders = item.weatherCounts.values.reduce(0, +)
            if totalWeatherOrders > 0 {
                let weatherRatio = Double(weatherCount) / Double(totalWeatherOrders)
                score += weatherRatio * 15.0
            }
        }
        
        return score
    }
    
    private func calculateConfidence(item: PredictionHistoryItem, context: PredictionContext) -> Double {
        var confidence: Double = 0.0
        var factors = 0
        
        // Frequency confidence (more orders = more confidence)
        if item.frequency >= 5 {
            confidence += 0.3
            factors += 1
        } else if item.frequency >= 3 {
            confidence += 0.2
            factors += 1
        }
        
        // Recency confidence
        let daysSince = Calendar.current.dateComponents([.day], from: item.lastOrderedAt, to: Date()).day ?? 999
        if daysSince <= 3 {
            confidence += 0.25
            factors += 1
        } else if daysSince <= 7 {
            confidence += 0.15
            factors += 1
        }
        
        // Time pattern confidence
        let timeSlotCount = item.timeSlotCounts[context.timeSlot.rawValue] ?? 0
        let totalOrders = item.timeSlotCounts.values.reduce(0, +)
        if totalOrders >= 3 && timeSlotCount >= 2 {
            let ratio = Double(timeSlotCount) / Double(totalOrders)
            confidence += ratio * 0.3
            factors += 1
        }
        
        // Day pattern confidence
        let dowCount = item.dayOfWeekCounts[context.dayOfWeek] ?? 0
        if dowCount >= 2 {
            confidence += 0.15
            factors += 1
        }
        
        // Weather pattern confidence
        if let weather = context.weather {
            let weatherCount = item.weatherCounts[weather.rawValue] ?? 0
            if weatherCount >= 1 {
                confidence += 0.1
                factors += 1
            }
        }
        
        // Normalize: require at least 2 factors to be confident
        return factors >= 2 ? min(confidence, 1.0) : 0.0
    }
    
    private func generateExplanation(item: PredictionHistoryItem, context: PredictionContext, confidence: Double) -> String {
        var reasons: [String] = []
        
        // Frequency
        if item.frequency >= 5 {
            reasons.append("You order this often")
        }
        
        // Recency
        let daysSince = Calendar.current.dateComponents([.day], from: item.lastOrderedAt, to: Date()).day ?? 999
        if daysSince <= 3 {
            reasons.append("Ordered recently")
        }
        
        // Time pattern
        let timeSlotCount = item.timeSlotCounts[context.timeSlot.rawValue] ?? 0
        let totalOrders = item.timeSlotCounts.values.reduce(0, +)
        if totalOrders >= 3 && timeSlotCount >= 2 {
            let timeLabel = context.timeSlot == .morning ? "mornings" :
                           context.timeSlot == .afternoon ? "afternoons" : "evenings"
            reasons.append("Often ordered in \(timeLabel)")
        }
        
        // Day pattern
        let dowCount = item.dayOfWeekCounts[context.dayOfWeek] ?? 0
        if dowCount >= 2 {
            let dayName = Calendar.current.weekdaySymbols[context.dayOfWeek - 1]
            reasons.append("Common on \(dayName)s")
        }
        
        // Weather
        if let weather = context.weather {
            let weatherCount = item.weatherCounts[weather.rawValue] ?? 0
            if weatherCount >= 1 {
                let weatherLabel = weather == .cold ? "cold days" :
                                 weather == .hot ? "hot days" : "rainy days"
                reasons.append("Perfect for \(weatherLabel)")
            }
        }
        
        // Confidence indicator
        let confidenceLabel = confidence >= highConfidence ? "Very confident" : "Good match"
        
        if reasons.isEmpty {
            return "\(confidenceLabel) based on your order history"
        } else {
            return "\(confidenceLabel): \(reasons.prefix(2).joined(separator: ", "))"
        }
    }
}
