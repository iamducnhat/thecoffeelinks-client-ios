//
//  PredictionRepository.swift
//  thecoffeelinks-client-ios
//
//  Local-only prediction data storage (on-device AI)
//

import Foundation

final class PredictionRepository: PredictionRepositoryProtocol, @unchecked Sendable {
    private let historyKey = "prediction_history"
    private let dismissalKey = "prediction_dismissals"
    private let suppressKey = "prediction_suppressed"
    private let lastSyncKey = "prediction_last_sync"
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    func getHistory() async -> [PredictionHistoryItem] {
        guard let data = defaults.data(forKey: historyKey),
              let items = try? decoder.decode([PredictionHistoryItem].self, from: data) else { return [] }
        return items
    }
    
    func saveHistory(_ items: [PredictionHistoryItem]) async {
        let trimmed = Array(items.suffix(100))
        if let data = try? encoder.encode(trimmed) { defaults.set(data, forKey: historyKey) }
    }
    
    func recordOrder(items: [CartItem], context: PredictionContext) async {
        var history = await getHistory()
        
        for item in items {
            let key = PredictionHistoryItem.makeKey(productId: item.product.id, customization: item.customization)
            
            if let index = history.firstIndex(where: { $0.key == key }) {
                history[index].frequency += item.quantity
                history[index].lastOrderedAt = Date()
                history[index].timeSlotCounts[context.timeSlot.rawValue, default: 0] += 1
                history[index].dayOfWeekCounts[context.dayOfWeek, default: 0] += 1
                if let weather = context.weather { history[index].weatherCounts[weather.rawValue, default: 0] += 1 }
            } else {
                var newItem = PredictionHistoryItem(
                    key: key, productId: item.product.id, productName: item.product.name,
                    customization: item.customization, frequency: item.quantity, lastOrderedAt: Date(),
                    timeSlotCounts: [context.timeSlot.rawValue: 1], dayOfWeekCounts: [context.dayOfWeek: 1], weatherCounts: [:]
                )
                if let weather = context.weather { newItem.weatherCounts[weather.rawValue] = 1 }
                history.append(newItem)
            }
        }
        
        await saveHistory(history)
    }
    
    func getDismissals() async -> [Date] {
        guard let data = defaults.data(forKey: dismissalKey),
              let dates = try? decoder.decode([Date].self, from: data) else { return [] }
        return dates
    }
    
    func recordDismissal() async {
        var dismissals = await getDismissals()
        dismissals.append(Date())
        if dismissals.count > 10 { dismissals = Array(dismissals.suffix(10)) }
        if let data = try? encoder.encode(dismissals) { defaults.set(data, forKey: dismissalKey) }
    }
    
    func clearDismissals() async { defaults.removeObject(forKey: dismissalKey) }
    
    func getSuppressedCombos() async -> Set<String> {
        guard let data = defaults.data(forKey: suppressKey),
              let list = try? decoder.decode([String].self, from: data) else { return [] }
        return Set(list)
    }
    
    func suppressCombo(_ key: String) async {
        var suppressed = await getSuppressedCombos()
        suppressed.insert(key)
        if let data = try? encoder.encode(Array(suppressed)) { defaults.set(data, forKey: suppressKey) }
    }

    func recordOrderFromHistory(order: Order) async {
        // Convert completed order to prediction history
        guard order.status == .completed || order.status == .cancelled else { return }

        var history = await getHistory()

        // Infer context from order timestamp
        let context = inferContext(from: order.createdAt)

        for item in order.items {
            let key = PredictionHistoryItem.makeKey(productId: item.productId, customization: item.customization)

            if let index = history.firstIndex(where: { $0.key == key }) {
                history[index].frequency += item.quantity
                // Only update lastOrderedAt if this order is more recent
                if order.createdAt > history[index].lastOrderedAt {
                    history[index].lastOrderedAt = order.createdAt
                }
                history[index].timeSlotCounts[context.timeSlot.rawValue, default: 0] += 1
                history[index].dayOfWeekCounts[context.dayOfWeek, default: 0] += 1
                if let weather = context.weather {
                    history[index].weatherCounts[weather.rawValue, default: 0] += 1
                }
            } else {
                var newItem = PredictionHistoryItem(
                    key: key,
                    productId: item.productId,
                    productName: item.productName,
                    customization: item.customization,
                    frequency: item.quantity,
                    lastOrderedAt: order.createdAt,
                    timeSlotCounts: [context.timeSlot.rawValue: 1],
                    dayOfWeekCounts: [context.dayOfWeek: 1],
                    weatherCounts: [:]
                )
                if let weather = context.weather {
                    newItem.weatherCounts[weather.rawValue] = 1
                }
                history.append(newItem)
            }
        }

        await saveHistory(history)
    }

    func getLastSyncDate() async -> Date? {
        return defaults.object(forKey: lastSyncKey) as? Date
    }

    func setLastSyncDate(_ date: Date) async {
        defaults.set(date, forKey: lastSyncKey)
    }

    private func inferContext(from date: Date) -> PredictionContext {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let dayOfWeek = calendar.component(.weekday, from: date)

        let timeSlot: TimeSlot
        switch hour {
        case 5..<11: timeSlot = .morning
        case 11..<14: timeSlot = .afternoon
        case 14..<18: timeSlot = .evening
        default: timeSlot = .night
        }

        return PredictionContext(timeSlot: timeSlot, dayOfWeek: dayOfWeek, weather: nil, location: nil)
    }
}
