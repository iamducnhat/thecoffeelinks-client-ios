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
    @Published var activeOrder: Order?
    @Published var isLoading = false
    
    private let orderRepository: OrderRepository
    private let realtimeService: RealtimeService
    private var cancellables = Set<AnyCancellable>()
    private var userId: String?
    
    // Status Progress Helper
    var progress: Double {
        guard let status = activeOrder?.status else { return 0 }
        switch status {
        case .placed: return 0.2
        // case .received: return 0.4
        case .preparing: return 0.6
        case .ready: return 0.8
        case .delivering: return 0.9
        case .completed: return 1.0
        case .cancelled: return 0.0
        case .pending: return 0.1
        }
    }
    
    var statusMessage: String {
        guard let order = activeOrder else { return "" }
        switch order.status {
        case .placed: return "Order Placed"
        // case .received: return "Kitchen Received"
        case .preparing: return "Barista Preparing"
        case .ready: 
            return order.mode == .delivery ? "Driver Heading Out" : "Ready for Pickup"
        case .delivering: return "Driver Nearby"
        case .completed: return "Enjoy!"
        default: return order.status.displayName
        }
    }
    
    init(orderRepository: OrderRepository, realtimeService: RealtimeService, userId: String? = nil) {
        self.orderRepository = orderRepository
        self.realtimeService = realtimeService
        self.userId = userId
        
        if let userId = userId {
            setupRealtime(userId: userId)
        }
    }
    
    func setUserId(_ id: String) {
        guard self.userId != id else { return }
        self.userId = id
        setupRealtime(userId: id)
        Task { await fetchActiveOrder() }
    }
    
    func fetchActiveOrder() async {
        await MainActor.run { isLoading = true }
        
        do {
            let orders = try await orderRepository.getActiveOrders()
            // Get most recent active order
            let latest = orders.sorted(by: { $0.createdAt > $1.createdAt }).first
            
            await MainActor.run {
                self.activeOrder = latest
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch active orders:", error)
            await MainActor.run { isLoading = false }
        }
    }
    
    private func setupRealtime(userId: String) {
        // Unsubscribe old if needed? RealtimeService handles dupes but good to be clean
        // For simplicity, just subscribe
        realtimeService.subscribe(to: "orders", filter: "user_id=eq.\(userId)")
        
        realtimeService.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .postgresChange(let change):
                    self?.handleOrderUpdate(change)
                case .connected:
                    print("Realtime Connected")
                default: break
                }
            }
            .store(in: &cancellables)
            
        realtimeService.connect()
    }
    
    private func handleOrderUpdate(_ change: PostgresChange) {
        // We only care about updates to OUR active order, or NEW orders
        guard let orderId = activeOrder?.id else {
            // If no active order, check if this is a new order for us
            if change.eventType == "INSERT" {
                 Task { await fetchActiveOrder() }
            }
            return
        }
        
        // If update is for current order
        if let newRecord = change.new, 
           let recordId = newRecord["id"]?.value as? String,
           recordId == orderId {
            
            // Update status locally
            if let statusStr = newRecord["status"]?.value as? String,
               let newStatus = OrderStatus(rawValue: statusStr) {
                
                // If completed/cancelled, refresh full list (might hide card)
                if !newStatus.isActive {
                     Task { await fetchActiveOrder() }
                     return
                }
                
                // Animate change
                withAnimation {
                    self.activeOrder?.status = newStatus
                }
            }
        }
    }
}
