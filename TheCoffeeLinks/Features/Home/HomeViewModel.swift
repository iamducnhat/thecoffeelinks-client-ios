//
//  HomeViewModel.swift
//  thecoffeelinks-client-ios
//
//  Home = Ordering Engine with AI predictions
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var vouchers: [Voucher] = []
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
    private let voucherRepository: VoucherRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let predictionRepository: PredictionRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let networkService: NetworkServiceProtocol
    private let predictionSyncService: PredictionSyncService
    private let aiRules = AIDominanceRules()
    private let refreshCoordinator: ContentRefreshCoordinator

    init(productRepository: ProductRepositoryProtocol, voucherRepository: VoucherRepositoryProtocol, favoritesRepository: FavoritesRepositoryProtocol,
         predictionRepository: PredictionRepositoryProtocol, userRepository: UserRepositoryProtocol,
         analyticsService: AnalyticsServiceProtocol, networkService: NetworkServiceProtocol,
         predictionSyncService: PredictionSyncService, refreshCoordinator: ContentRefreshCoordinator) {
        self.productRepository = productRepository
        self.voucherRepository = voucherRepository
        self.favoritesRepository = favoritesRepository
        self.predictionRepository = predictionRepository
        self.userRepository = userRepository
        self.analyticsService = analyticsService
        self.networkService = networkService
        self.predictionSyncService = predictionSyncService
        self.refreshCoordinator = refreshCoordinator
    }
    
    func load() async {
        // 1. Immediate Cache Load (Synchronous-like)
        await loadCachedContent()

        // 2. Sync order history for predictions (background, non-blocking)
        Task.detached { [weak self] in
            guard let self = self else { return }
            do {
                try await self.predictionSyncService.syncOrderHistory()
                // Regenerate prediction after sync
                await self.generatePrediction()
            } catch {
                debugLog("[HomeViewModel] Prediction sync failed: \(error)")
            }
        }

        // 3. Background Refresh (Non-blocking)
        await refreshCoordinator.schedule(id: "home_refresh", priority: .high) { [weak self] in
            await self?.performRefresh()
        }

        await analyticsService.trackScreen("Home")
    }
    
    private func loadCachedContent() async {
        // Load cached popular products
        if let cachedPopulars = await productRepository.getCachedPopularProducts() {
            self.popularProducts = cachedPopulars
        }
        
        // Load cached vouchers
        if let cachedVouchers = await voucherRepository.getCachedVouchers() {
            self.vouchers = cachedVouchers.filter { $0.isValid }
        }
        
        // Load cached favorites
        if let cachedFavs = await favoritesRepository.getCachedFavorites() {
            self.favorites = cachedFavs
        }
        
        // For now, prediction is local DB so we load it
        await generatePrediction()
    }
    
    private func performRefresh() async {
        isRefreshing = true
        async let eventsTask: () = loadEvents()
        async let vouchersTask: () = loadVouchers()
        async let popularsTask: () = loadPopularProducts()
        async let favsTask: () = loadFavorites()
        async let predictionTask: () = generatePrediction()
        
        _ = await (eventsTask, vouchersTask, popularsTask, favsTask, predictionTask)
        isRefreshing = false
    }
    
    private func loadEvents() async {
        do {
            let response: EventsResponse = try await networkService.get("/api/events", queryItems: nil)
            events = response.events
        } catch {
            debugLog("⚠️ Events fetch error: \(error)")
        }
    }
    
    private func loadVouchers() async {
        do {
            let allVouchers: [Voucher]

            if let user = await userRepository.getCachedUser(), user.id != "guest" {
                do {
                    allVouchers = try await voucherRepository.fetchAndDistributeVouchers(userId: user.id)
                } catch {
                    debugLog("⚠️ Voucher distribution fallback to refresh: \(error)")
                    allVouchers = try await voucherRepository.refreshVouchers()
                }
            } else {
                allVouchers = try await voucherRepository.refreshVouchers()
            }

            // Only show active vouchers in the banner
            vouchers = allVouchers.filter { $0.isValid }
        } catch {
            debugLog("⚠️ Vouchers fetch error: \(error)")
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
        do { popularProducts = try await productRepository.refreshPopularProducts(period: "daily", limit: 10) }
        catch { self.error = error }
    }
    
    private func loadFavorites() async {
        do { favorites = try await favoritesRepository.refreshFavorites() }
        catch { self.error = error }
    }
    
    private func generatePrediction() async {
        let history = await predictionRepository.getHistory()
        guard history.count >= aiRules.minOrdersForAI else { predictedCart = nil; aiConfidence = 0; return }

        let dismissals = await predictionRepository.getDismissals()
        let recentDismissals = dismissals.filter { Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 365 < aiRules.dismissalWindowDays }
        guard recentDismissals.count < aiRules.maxDismissals else { predictedCart = nil; aiConfidence = 0; return }

        let context = PredictionContext.current
        let suppressed = await predictionRepository.getSuppressedCombos()
        var scoredItems: [(PredictionHistoryItem, Double)] = []

        for item in history {
            // Skip suppressed items
            guard !suppressed.contains(item.key) else { continue }

            let score = calculateScore(item: item, context: context)
            if score >= aiRules.minConfidence {
                scoredItems.append((item, score))
            }
        }
        scoredItems.sort { $0.1 > $1.1 }

        // Take top 3 items for prediction
        let topItems = Array(scoredItems.prefix(3))
        guard !topItems.isEmpty else { predictedCart = nil; aiConfidence = 0; return }

        // Build predicted cart items by looking up products
        var predictedItems: [PredictedCartItem] = []

        for (historyItem, score) in topItems {
            // Try to get the product from repository
            if let product = try? await productRepository.getProduct(id: historyItem.productId) {
                let predictedItem = PredictedCartItem(
                    id: UUID(),
                    product: product,
                    customization: historyItem.customization,
                    quantity: 1 // Default to 1, user can adjust
                )
                predictedItems.append(predictedItem)
            }
        }

        guard !predictedItems.isEmpty else { predictedCart = nil; aiConfidence = 0; return }

        aiConfidence = topItems.first?.1 ?? 0
        let reason = generateReason(context: context, topItem: topItems.first!.0)
        predictedCart = PredictedCart(
            id: UUID(),
            items: predictedItems,
            confidence: aiConfidence,
            reason: reason,
            generatedAt: Date()
        )
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
