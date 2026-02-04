//
//  DeliveryStorePickerSheet.swift
//  TheCoffeeLinks
//
//  Cart-aware store selection sheet for delivery orders
//

import SwiftUI
import MapKit

struct DeliveryStorePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storeViewModel: StoreViewModel
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var cartViewModel: CartViewModel
    
    @State private var storeScores: [StoreScore] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let scoreCalculator = StoreScoreCalculator()
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if storeScores.isEmpty {
                    emptyView
                } else {
                    storeListView
                }
            }
            .navigationTitle("Select Delivery Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await loadStoreScores()
            }
        }
    }
    
    // MARK: - Store List View
    
    private var storeListView: some View {
        List {
            if let recommended = storeScores.first {
                Section {
                    StoreScoreCard(
                        score: recommended,
                        isSelected: recommended.store.id == cartViewModel.cart.storeId,
                        cartItems: cartViewModel.cart.items
                    )
                    .onTapGesture {
                        selectStore(recommended.store)
                    }
                } header: {
                    Text("RECOMMENDED")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            if storeScores.count > 1 {
                Section {
                    ForEach(storeScores.dropFirst()) { score in
                        StoreScoreCard(
                            score: score,
                            isSelected: score.store.id == cartViewModel.cart.storeId,
                            cartItems: cartViewModel.cart.items
                        )
                        .onTapGesture {
                            selectStore(score.store)
                        }
                    }
                } header: {
                    Text("OTHER AVAILABLE STORES")
                        .font(.caption)
                }
            }
            
            Section {
                Text("Stores are ranked by product availability, delivery fee, and estimated delivery time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Loading & Error States
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Finding best stores...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Unable to Load Stores")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                Task { await loadStoreScores() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "storefront")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Stores Available")
                .font(.headline)
            Text("No stores can deliver to this address.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func loadStoreScores() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Ensure we have an address
        guard let address = cartViewModel.selectedAddress else {
            errorMessage = "Please select a delivery address first"
            return
        }
        
        // Get delivery-capable stores
        let deliveryStores = storeViewModel.stores.filter { $0.deliveryAvailable == true }
        
        guard !deliveryStores.isEmpty else {
            errorMessage = "No stores offer delivery service"
            return
        }
        
        // Fetch delivery availability for each store in parallel
        var availabilities: [String: DeliveryAvailability] = [:]
        
        await withTaskGroup(of: (String, DeliveryAvailability?).self) { group in
            for store in deliveryStores {
                group.addTask {
                    do {
                        let availability = try await deliveryViewModel.checkDeliveryAvailability(
                            for: store.id,
                            addressId: address.id
                        )
                        return (store.id, availability)
                    } catch {
                        print("⚠️ Failed to check availability for store \(store.id): \(error)")
                        return (store.id, nil)
                    }
                }
            }
            
            for await (storeId, availability) in group {
                if let availability = availability {
                    availabilities[storeId] = availability
                }
            }
        }
        
        // Filter to only available stores
        let availableStores = deliveryStores.filter { store in
            availabilities[store.id]?.available == true
        }
        
        guard !availableStores.isEmpty else {
            errorMessage = "No stores can deliver to this address"
            return
        }
        
        // Calculate scores
        let userLocation = address.coordinates.map { coord in
            CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
        }
        
        let scores = scoreCalculator.calculateScores(
            stores: availableStores,
            availabilities: availabilities,
            cartItems: cartViewModel.cart.items,
            userLocation: userLocation
        )
        
        await MainActor.run {
            self.storeScores = scores
            
            // Auto-select recommended store if cart is empty
            if cartViewModel.cart.items.isEmpty, let best = scores.first {
                cartViewModel.setStore(best.store.id)
                storeViewModel.selectStore(best.store)
            }
        }
    }
    
    private func selectStore(_ store: Store) {
        // Check if cart has items from different store
        if !cartViewModel.cart.items.isEmpty,
           let currentStoreId = cartViewModel.cart.storeId,
           currentStoreId != store.id {
            
            // Show confirmation alert via CartViewModel
            cartViewModel.conflictingStore = store
            cartViewModel.showStoreConflictAlert = true
            dismiss()
            return
        }
        
        // Update both view models
        cartViewModel.setStore(store.id)
        storeViewModel.selectStore(store)
        
        // Trigger delivery availability check
        Task {
            await cartViewModel.checkDeliveryAvailability()
        }
        
        dismiss()
    }
}

// MARK: - Store Score Card

struct StoreScoreCard: View {
    let score: StoreScore
    let isSelected: Bool
    let cartItems: [CartItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Store name + Badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(score.store.name)
                        .font(.headline)
                    
                    if score.distance > 0 {
                        Text(String(format: "%.1f km away", score.distance))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if score.isPrimary {
                    StoreBadge(text: "RECOMMENDED", color: .green)
                } else if isSelected {
                    StoreBadge(text: "CURRENT", color: .blue)
                }
            }
            
            // Reasons
            if !score.reasons.isEmpty {
                HStack(spacing: 8) {
                    ForEach(score.reasons, id: \.self) { reason in
                        ReasonTag(reason: reason)
                    }
                }
            }
            
            // Delivery Info
            HStack(spacing: 16) {
                if let fee = score.availability.fee {
                    InfoItem(
                        icon: "dollarsign.circle",
                        title: "Delivery Fee",
                        value: formatCurrency(fee.amount)
                    )
                }
                
                if let eta = score.availability.eta {
                    InfoItem(
                        icon: "clock",
                        title: "ETA",
                        value: "\(eta.minutes) min"
                    )
                }
            }
            
            // Availability Warning
            if score.unavailableItemsCount > 0 {
                availabilityWarning
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private var availabilityWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            Text("\(score.unavailableItemsCount) item(s) unavailable at this store")
                .font(.caption)
                .foregroundColor(.orange)
            
            Spacer()
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))đ"
    }
}

// MARK: - Supporting Views

struct StoreBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(4)
    }
}

struct ReasonTag: View {
    let reason: ScoreReason
    
    var body: some View {
        HStack(spacing: 4) {
            Text(reason.emoji)
                .font(.caption2)
            Text(reason.displayText)
                .font(.caption)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    Text("Delivery Store Picker")
        .font(.title)
}
