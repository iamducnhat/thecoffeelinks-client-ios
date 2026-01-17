import Foundation
import Combine

// MARK: - AI Models

struct ContextSignal: Codable {
    let timeSlot: TimeSlot
    let dayOfWeek: Int // 1 = Sunday
    let weatherCondition: String // "sunny", "rainy", etc.
    let locationType: String // "home", "work", "store", "transit"
}

struct PredictedOrder: Identifiable, Codable {
    let id: String
    let products: [Product]
    let confidenceScore: Double // 0.0 - 1.0
    let reasoning: String // "You usually order this on rainy mornings"
}

// MARK: - AI Services

class WeatherService: ObservableObject {
    @Published var currentCondition: String = "sunny"
    @Published var temperature: Double = 25.0
    
    func fetchWeather() {
        // Mock implementation for now
        // In real app: Call WeatherKit or OpenWeatherMap
        let conditions = ["sunny", "rainy", "cloudy"]
        self.currentCondition = conditions.randomElement() ?? "sunny"
    }
}

class PredictionEngine {
    static let shared = PredictionEngine()
    
    func predictOrder(history: [Order], context: ContextSignal) -> PredictedOrder? {
        // Simple heuristic rules for V2 (Server would do ML)
        
        // 1. Check for "Usual" (high frequency item)
        // 2. Filter by time of day
        
        if context.timeSlot == .morning {
            // Find morning orders
            return PredictedOrder(
                id: UUID().uuidString,
                products: [], // Populate with dummy logic or passed history
                confidenceScore: 0.85,
                reasoning: "Your morning fuel"
            )
        }
        
        return nil
    }
}
