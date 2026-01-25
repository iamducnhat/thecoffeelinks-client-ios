//
//  PredictionSyncService.swift
//  thecoffeelinks-client-ios
//
//  Syncs order history from server to build prediction patterns
//

import Foundation

final class PredictionSyncService: Sendable {
    private let orderRepository: OrderRepositoryProtocol
    private let predictionRepository: PredictionRepositoryProtocol

    init(orderRepository: OrderRepositoryProtocol, predictionRepository: PredictionRepositoryProtocol) {
        self.orderRepository = orderRepository
        self.predictionRepository = predictionRepository
    }

    /// Sync order history from server to local prediction history
    /// Only syncs completed orders to learn user patterns
    func syncOrderHistory(force: Bool = false) async throws {
        // Check if we need to sync
        let lastSync = await predictionRepository.getLastSyncDate()
        let now = Date()

        // Only sync once per day unless forced
        if !force, let lastSync = lastSync {
            let daysSinceSync = Calendar.current.dateComponents([.day], from: lastSync, to: now).day ?? 0
            if daysSinceSync < 1 {
                print("[PredictionSync] Skipping sync - last synced \(daysSinceSync) days ago")
                return
            }
        }

        print("[PredictionSync] Starting order history sync...")

        // Fetch all orders from server
        // We fetch all because the API doesn't support date filtering properly
        let response = try await orderRepository.getOrders(status: nil, limit: 500, offset: 0)

        // Filter for completed orders only (we learn from successful orders)
        let completedOrders = response.orders.filter { $0.status == .completed }

        print("[PredictionSync] Found \(completedOrders.count) completed orders")

        // Convert each order to prediction history
        for order in completedOrders {
            await predictionRepository.recordOrderFromHistory(order: order)
        }

        // Update last sync date
        await predictionRepository.setLastSyncDate(now)

        let history = await predictionRepository.getHistory()
        print("[PredictionSync] Sync complete - \(history.count) unique items in history")
    }

    /// Get current prediction statistics
    func getStats() async -> PredictionStats {
        let history = await predictionRepository.getHistory()
        let totalItems = history.count
        let totalOrders = history.reduce(0) { $0 + $1.frequency }
        let mostOrdered = history.max(by: { $0.frequency < $1.frequency })
        let lastSync = await predictionRepository.getLastSyncDate()

        return PredictionStats(
            uniqueItems: totalItems,
            totalOrders: totalOrders,
            mostOrderedItem: mostOrdered?.productName,
            mostOrderedCount: mostOrdered?.frequency ?? 0,
            lastSyncDate: lastSync
        )
    }
}

struct PredictionStats {
    let uniqueItems: Int
    let totalOrders: Int
    let mostOrderedItem: String?
    let mostOrderedCount: Int
    let lastSyncDate: Date?
}
