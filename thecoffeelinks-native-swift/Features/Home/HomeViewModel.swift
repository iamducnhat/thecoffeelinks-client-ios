//
//  HomeViewModel.swift
//  thecoffeelinks-native-swift
//
//  Home = Ordering Engine with AI predictions
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var popularProducts: [PopularProduct] = []
    @Published var favorites: [FavoriteItem] = []
    @Published var predictedCart: PredictedCart?
    @Published var currentStore: Store?
    @Published var orderingMode: OrderingMode = .pickup
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var aiConfidence: Double = 0
    @Published var isDismissedThisSession = false
    
    private let productRepository: ProductRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let predictionRepository: PredictionRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let networkService: NetworkServiceProtocol
    private let aiRules = AIDominanceRules()
    
    init(productRepository: ProductRepositoryProtocol, favoritesRepository: FavoritesRepositoryProtocol,
         predictionRepository: PredictionRepositoryProtocol, userRepository: UserRepositoryProtocol, 
         analyticsService: AnalyticsServiceProtocol, networkService: NetworkServiceProtocol) {
        self.productRepository = productRepository
        self.favoritesRepository = favoritesRepository
        self.predictionRepository = predictionRepository
        self.userRepository = userRepository
        self.analyticsService = analyticsService
        self.networkService = networkService
    }
    
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        await analyticsService.trackScreen("Home")
        
        async let eventsTask = loadEvents()
        async let populars = loadPopularProducts()
        async let favs = loadFavorites()
        async let prediction = generatePrediction()
        await eventsTask; await populars; await favs; await prediction
        
        isLoading = false
    }
    
    private func loadEvents() async {
        do {
            let response: EventsResponse = try await networkService.get("/api/events", queryItems: nil)
            events = response.events
        } catch {
            print("⚠️ Events fetch error: \(error)")
            // Events are non-critical, continue with empty
        }
    }
    
    func refresh() async { isRefreshing = true; await load(); isRefreshing = false }
    func setOrderingMode(_ mode: OrderingMode) { orderingMode = mode }
    
    var shouldShowAICard: Bool {
        aiRules.shouldShowAICard(confidence: aiConfidence, orderHistory: 5, dismissedThisSession: isDismissedThisSession,
                                 cartHasItems: false, isUnusualTime: false, isSuppressed: false)
    }
    
    var predictionLanguage: String { predictedCart?.confidenceLevel.displayPrefix ?? "Your usual" }
    
    func dismissPrediction() {
        isDismissedThisSession = true
        Task { await predictionRepository.recordDismissal() }
        predictedCart = nil
    }
    
    func acceptPrediction() {
        isDismissedThisSession = false
        Task { await predictionRepository.clearDismissals() }
    }
    
    func resetSession() { isDismissedThisSession = false }
    
    private func loadPopularProducts() async {
        do { popularProducts = try await productRepository.getPopularProducts(period: "daily", limit: 10) }
        catch { self.error = error }
    }
    
    private func loadFavorites() async {
        do { favorites = try await favoritesRepository.getFavorites() }
        catch { self.error = error }
    }
    
    private func generatePrediction() async {
        let history = await predictionRepository.getHistory()
        guard history.count >= aiRules.minOrdersForAI else { predictedCart = nil; aiConfidence = 0; return }
        
        let dismissals = await predictionRepository.getDismissals()
        let recentDismissals = dismissals.filter { Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 365 < aiRules.dismissalWindowDays }
        guard recentDismissals.count < aiRules.maxDismissals else { predictedCart = nil; aiConfidence = 0; return }
        
        let context = PredictionContext.current
        var scoredItems: [(PredictionHistoryItem, Double)] = []
        
        for item in history {
            let score = calculateScore(item: item, context: context)
            scoredItems.append((item, score))
        }
        scoredItems.sort { $0.1 > $1.1 }
        
        guard let topItem = scoredItems.first, topItem.1 >= aiRules.minConfidence else { predictedCart = nil; aiConfidence = 0; return }
        
        aiConfidence = topItem.1
        let reason = generateReason(context: context, topItem: topItem.0)
        predictedCart = PredictedCart(id: UUID(), items: [], confidence: aiConfidence, reason: reason, generatedAt: Date())
    }
    
    private func calculateScore(item: PredictionHistoryItem, context: PredictionContext) -> Double {
        var score: Double = 0
        score += min(Double(item.frequency), 30) / 30.0 * 0.3
        let daysSince = Calendar.current.dateComponents([.day], from: item.lastOrderedAt, to: Date()).day ?? 365
        score += max(0, 1.0 - (Double(daysSince) / 30.0)) * 0.2
        score += min(Double(item.timeSlotCounts[context.timeSlot.rawValue] ?? 0), 10) / 10.0 * 0.25
        score += min(Double(item.dayOfWeekCounts[context.dayOfWeek] ?? 0), 5) / 5.0 * 0.15
        if let weather = context.weather { score += min(Double(item.weatherCounts[weather.rawValue] ?? 0), 5) / 5.0 * 0.1 }
        return min(score, 1.0)
    }
    
    private func generateReason(context: PredictionContext, topItem: PredictionHistoryItem) -> PredictionReason {
        let timeSlotOrders = topItem.timeSlotCounts[context.timeSlot.rawValue] ?? 0
        let dayOrders = topItem.dayOfWeekCounts[context.dayOfWeek] ?? 0
        
        if timeSlotOrders >= 5 && dayOrders >= 3 { return .timeOfDay(context.timeSlot) }
        if timeSlotOrders >= 5 { return .timeOfDay(context.timeSlot) }
        if dayOrders >= 3 { return .dayOfWeek(Calendar.current.weekdaySymbols[context.dayOfWeek - 1]) }
        if topItem.frequency >= 10 { return .frequency }
        return .custom("Based on your history")
    }
}
