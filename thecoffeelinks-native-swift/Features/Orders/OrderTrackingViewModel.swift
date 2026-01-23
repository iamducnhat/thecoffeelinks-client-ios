//
//  OrderTrackingViewModel.swift
//  thecoffeelinks-native-swift
//
//  ViewModel for Order Tracking Card
//  Handles fetching active order and realtime status updates.
//

import Foundation
import Combine
import SwiftUI

class OrderTrackingViewModel: ObservableObject {
    @Published var activeOrders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRealtimeConnected = false
    
    private let orderRepository: OrderRepository
    private let realtimeService: RealtimeService
    private var cancellables = Set<AnyCancellable>()
    private var userId: String?
    
    init(orderRepository: OrderRepository, realtimeService: RealtimeService, userId: String? = nil) {
        self.orderRepository = orderRepository
        self.realtimeService = realtimeService
        self.userId = userId
        
        setupBindings()
        
        if let userId = userId {
            setupRealtime(userId: userId)
        }
    }
    
    private func setupBindings() {
        // Monitor Realtime Connection State
        realtimeService.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .connected:
                    self?.isRealtimeConnected = true
                    self?.errorMessage = nil
                case .disconnected(let error):
                    self?.isRealtimeConnected = false
                    if let error = error {
                        self?.errorMessage = "Realtime disconnected: \(error.localizedDescription)"
                    }
                case .postgresChange(let change):
                    self?.handleOrderUpdate(change)
                default: break
                }
            }
            .store(in: &cancellables)
    }
    
    func setUserId(_ id: String) {
        guard self.userId != id else { return }
        self.userId = id
        setupRealtime(userId: id)
        Task { await fetchActiveOrders() }
    }
    
    func fetchActiveOrders() async {
        await MainActor.run { 
            isLoading = true 
            errorMessage = nil
        }
        
        do {
            let orders = try await orderRepository.getActiveOrders()
            // Sort by creation date descending (newest first)
            let sorted = orders.sorted(by: { $0.createdAt > $1.createdAt })
            
            await MainActor.run {
                self.activeOrders = sorted
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch active orders:", error)
            await MainActor.run { 
                self.isLoading = false
                self.errorMessage = "Failed to load orders: \(error.localizedDescription)"
            }
        }
    }
    
    private func setupRealtime(userId: String) {
        // Unsubscribe old if needed? RealtimeService handles dupes but good to be clean
        // For simplicity, just subscribe
        realtimeService.subscribe(to: "orders", filter: "user_id=eq.\(userId)")
        
        // Ensure connection
        if !realtimeService.isConnected {
            realtimeService.connect()
        }
    }
    
    private func handleOrderUpdate(_ change: PostgresChange) {
        guard let changeType = change.eventType as String? else { return }
        
        // Handle INSERT
        if changeType == "INSERT" {
             Task { await fetchActiveOrders() }
             return
        }
        
        // Handle UPDATE
        if changeType == "UPDATE",
           let newRecord = change.new,
           let recordId = newRecord["id"]?.value as? String {
            
            // Find index of order being updated
            if let index = activeOrders.firstIndex(where: { $0.id == recordId }) {
                // Update specific properties locally to avoid full refetch flicker
                if let statusStr = newRecord["status"]?.value as? String,
                   let newStatus = OrderStatus(rawValue: statusStr) {
                    
                    // Update local model first so UI reflects the change (especially 'completed')
                    withAnimation {
                        var updatedOrder = activeOrders[index]
                        updatedOrder.status = newStatus
                        updatedOrder.updatedAt = Date() // Approximate
                        activeOrders[index] = updatedOrder
                    }
                    
                    // If status changes to non-active (completed/cancelled), 
                    // schedule a refresh to remove it after allowing the user to see the "Completed" state.
                    if !newStatus.isActive {
                        // Delay 8 seconds to allow completion animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                            Task { [weak self] in await self?.fetchActiveOrders() }
                        }
                    }
                }
            }
        }
    }
}
 

