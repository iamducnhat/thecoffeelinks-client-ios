//
//  DeliveryService.swift
//  thecoffeelinks-native-swift
//
//  Manages delivery addresses, zones, ETA calculation, and delivery fees.
//

import Foundation
import Combine
import CoreLocation

@MainActor
class DeliveryService: ObservableObject {
    static let shared = DeliveryService()
    
    @Published var savedAddresses: [DeliveryAddress] = []
    @Published var selectedAddress: DeliveryAddress?
    @Published var estimatedETA: Int? // minutes
    @Published var deliveryFee: Double = 0
    @Published var isInDeliveryZone: Bool = true
    @Published var isLoading = false
    @Published var error: String?
    
    private let storageKey = "delivery_addresses_v2"
    private let baseDeliveryFee: Double = 15000 // 15k VND
    private let perKmFee: Double = 5000 // 5k per km
    private let maxDeliveryDistance: Double = 10 // km
    
    private init() {
        loadFromStorage()
    }
    
    // MARK: - Address Management
    
    /// Get default address (first one marked as default, or most recently used)
    var defaultAddress: DeliveryAddress? {
        savedAddresses.first { $0.isDefault } ?? savedAddresses.max { ($0.lastUsedAt ?? .distantPast) < ($1.lastUsedAt ?? .distantPast) }
    }
    
    /// Get addresses sorted by usage (most used first)
    func getAddressesSortedByUsage() -> [DeliveryAddress] {
        savedAddresses.sorted { $0.usageCount > $1.usageCount }
    }
    
    /// Add new address
    func addAddress(_ address: DeliveryAddress) {
        var newAddress = address
        
        // If this is first address or marked as default, make it default
        if savedAddresses.isEmpty || address.isDefault {
            // Unset other defaults
            for i in savedAddresses.indices {
                savedAddresses[i].isDefault = false
            }
            newAddress.isDefault = true
        }
        
        savedAddresses.insert(newAddress, at: 0)
        saveToStorage()
    }
    
    /// Update address
    func updateAddress(_ address: DeliveryAddress) {
        if let index = savedAddresses.firstIndex(where: { $0.id == address.id }) {
            savedAddresses[index] = address
            saveToStorage()
        }
    }
    
    /// Delete address
    func deleteAddress(_ id: String) {
        savedAddresses.removeAll { $0.id == id }
        if selectedAddress?.id == id {
            selectedAddress = defaultAddress
        }
        saveToStorage()
    }
    
    /// Set address as default
    func setAsDefault(_ id: String) {
        for i in savedAddresses.indices {
            savedAddresses[i].isDefault = savedAddresses[i].id == id
        }
        saveToStorage()
    }
    
    /// Select address for current order
    func selectAddress(_ address: DeliveryAddress) {
        var updated = address
        updated.lastUsedAt = Date()
        updated.usageCount += 1
        
        if let index = savedAddresses.firstIndex(where: { $0.id == address.id }) {
            savedAddresses[index] = updated
        }
        
        selectedAddress = updated
        calculateDeliveryDetails()
        saveToStorage()
    }
    
    /// Auto-select best address (ranked by usage, then default)
    func autoSelectAddress() {
        // Priority: default > most used > most recent
        if let defaultAddr = savedAddresses.first(where: { $0.isDefault }) {
            selectAddress(defaultAddr)
        } else if let mostUsed = getAddressesSortedByUsage().first {
            selectAddress(mostUsed)
        }
    }
    
    // MARK: - Delivery Calculation
    
    /// Calculate ETA and fees for selected address
    func calculateDeliveryDetails() {
        guard let address = selectedAddress else {
            estimatedETA = nil
            deliveryFee = 0
            return
        }
        
        // Base ETA: 20-35 min depending on time of day
        let hour = Calendar.current.component(.hour, from: Date())
        let isPeakHour = (hour >= 11 && hour <= 13) || (hour >= 17 && hour <= 19)
        
        let baseETA = isPeakHour ? 30 : 20
        let variability = Int.random(in: 0...10)
        estimatedETA = baseETA + variability
        
        // Calculate fee based on distance (if coordinates available)
        if let coords = address.coordinates {
            let distanceKm = calculateDistanceToNearestStore(from: coords)
            if distanceKm > maxDeliveryDistance {
                isInDeliveryZone = false
                deliveryFee = 0
            } else {
                isInDeliveryZone = true
                deliveryFee = baseDeliveryFee + (distanceKm * perKmFee)
            }
        } else {
            // Default fee if no coordinates
            isInDeliveryZone = true
            deliveryFee = baseDeliveryFee
        }
    }
    
    /// Check if address is in delivery zone
    func validateDeliveryZone(for address: DeliveryAddress) async -> Bool {
        // TODO: Server-side validation
        // For now, assume all addresses are valid
        return true
    }
    
    /// Get ETA display string
    var etaDisplay: String? {
        guard let eta = estimatedETA else { return nil }
        let arrivalTime = Calendar.current.date(byAdding: .minute, value: eta, to: Date())
        
        if let time = arrivalTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Arrives by \(formatter.string(from: time))"
        }
        return "Ready in \(eta) min"
    }
    
    /// Get delivery fee display
    var feeDisplay: String {
        deliveryFee.toVND()
    }
    
    // MARK: - Distance Calculation
    
    private func calculateDistanceToNearestStore(from coords: DeliveryAddress.Coordinates) -> Double {
        // Placeholder: Calculate distance to nearest store
        // In production, use actual store coordinates
        let storeLocation = CLLocation(latitude: 10.762622, longitude: 106.660172) // HCMC center
        let userLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
        return userLocation.distance(from: storeLocation) / 1000 // Convert to km
    }
    
    // MARK: - Storage
    
    private func loadFromStorage() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let addresses = try? JSONDecoder().decode([DeliveryAddress].self, from: data) {
            savedAddresses = addresses
        }
    }
    
    private func saveToStorage() {
        if let data = try? JSONEncoder().encode(savedAddresses) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

// MARK: - Delivery Menu Filtering

extension DeliveryService {
    /// Filter products that are safe for delivery
    func filterDeliverableProducts(_ products: [Product]) -> [Product] {
        products.filter { isProductDeliverable($0) }
    }
    
    /// Check if a specific product is deliverable
    func isProductDeliverable(_ product: Product) -> Bool {
        // Products with "pastries" category might not travel well
        // Ice-heavy drinks may not be ideal
        // TODO: Add `isDeliverable` field to Product model from server
        
        let category = product.category?.lowercased() ?? ""
        
        // Categories that don't deliver well
        let nonDeliverableCategories = ["ice_cream", "smoothie_bowl"]
        
        if nonDeliverableCategories.contains(category) {
            return false
        }
        
        return true
    }
    
    /// Get delivery notes for a product
    func getDeliveryNotes(for product: Product) -> String? {
        let category = product.category?.lowercased() ?? ""
        
        if category.contains("iced") || category.contains("cold") {
            return "Ice-packed for transit"
        } else if category.contains("hot") || category.contains("coffee") || category.contains("tea") {
            return "Sealed at 85°C, stays hot 30min"
        } else if category.contains("pastry") || category.contains("cake") {
            return "Carefully packaged"
        }
        
        return nil
    }
}
