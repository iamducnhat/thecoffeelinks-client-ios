//
//  OrderTrackingViewModel.swift
//  thecoffeelinks-client-ios
//
//  ViewModel for Order Tracking Card
//  Handles fetching active order and realtime status updates.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class OrderTrackingViewModel: ObservableObject {
    @Published var activeOrders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRealtimeConnected = false
    
    // VNPay Support
    @Published var showingPaymentWebView = false
    @Published var paymentUrl: URL?
    
    private let orderRepository: OrderRepository
    private let realtimeService: RealtimeService
    private var cancellables = Set<AnyCancellable>()
    private var userId: String?
    
    init(orderRepository: OrderRepository, realtimeService: RealtimeService, userId: String? = nil) {
        self.orderRepository = orderRepository
        self.realtimeService = realtimeService
        self.userId = userId
        
        setupBindings()
        
        // Initial fetch if user is already known
        if let userId = userId {
            self.setUserId(userId)
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
                    // Re-fetch on reconnect to ensure no missed events
                    Task { [weak self] in await self?.fetchActiveOrders() }
                    
                case .disconnected(let error):
                    self?.isRealtimeConnected = false
                    if let error = error {
                        print("[OrderTracking] Realtime disconnected: \(error.localizedDescription)")
                    }
                    
                case .postgresChange(let change):
                    self?.handleOrderUpdate(change)
                    
                default: break
                }
            }
            .store(in: &cancellables)
    }
    
    func setUserId(_ id: String) {
        let isNewUser = self.userId != id
        self.userId = id
        
        if isNewUser {
            // Reset state for new user
            self.activeOrders = []
            self.errorMessage = nil
            setupRealtime()
        }
        
        // Always attempt a fetch when setUserId is called (e.g. onAppear), 
        // to ensure we have the latest state even if the userId hasn't changed.
        Task { await fetchActiveOrders() }
    }
    
    func fetchActiveOrders() async {
        await MainActor.run { 
            if activeOrders.isEmpty { isLoading = true } // Only show load spinner if empty
        }
        
        do {
            let orders = try await orderRepository.getActiveOrders()
            // Sort by newest first
            let sorted = orders.sorted(by: { $0.createdAt > $1.createdAt })
            
            await MainActor.run {
                withAnimation {
                    self.activeOrders = sorted
                }
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch active orders:", error)
            await MainActor.run { 
                self.isLoading = false
                // Don't show error message to user for background fetches, just log it.
                // Only show if list is empty and user explicitly requested it (refinement).
                if self.activeOrders.isEmpty {
                     // self.errorMessage = "Could not load orders."
                }
            }
        }
    }
    
    private func setupRealtime() {
        // Subscribe to 'orders' table
        // RLS policies on Server ensure we only receive our own orders
        realtimeService.subscribe(to: "orders")
        
        // Ensure connection
        if !realtimeService.isConnected {
            realtimeService.connect()
        }
    }
    
    private func handleOrderUpdate(_ change: PostgresChange) {
        guard let changeType = change.eventType as String? else { return }
        print("[OrderViewModel] Realtime Event: \(changeType)")
        
        // Handle INSERT: New order placed (maybe on another device)
        if changeType == "INSERT" {
             Task { await fetchActiveOrders() }
             return
        }
        
        // Handle UPDATE
        if changeType == "UPDATE",
           let newRecord = change.new,
           let recordId = newRecord["id"]?.value as? String {
            
            // Check if this order is in our active list
            if let index = activeOrders.firstIndex(where: { $0.id == recordId }) {
                guard let statusStr = newRecord["status"]?.value as? String,
                      let newStatus = OrderStatus(rawValue: statusStr) else { return }
                
                print("[OrderViewModel] Order \(recordId) -> \(newStatus.displayName)")
                
                // Update local state smoothly
                withAnimation {
                    var updatedOrder = activeOrders[index]
                    updatedOrder.status = newStatus
                    updatedOrder.updatedAt = Date()
                    activeOrders[index] = updatedOrder
                }
                
                // If order is completed/cancelled, remove it after a delay
                if !newStatus.isActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                        withAnimation {
                            self?.activeOrders.removeAll(where: { $0.id == recordId })
                        }
                    }
                }
            } else {
                // We don't have this order, but maybe we should?
                // If it's active now, fetch it.
                 Task { await fetchActiveOrders() }
            }
        }
    }

    // MARK: - Payment Handlers
    
    func resumePayment(for order: Order) {
        guard let urlString = order.paymentUrl, let url = URL(string: urlString) else { return }
        self.paymentUrl = url
        self.showingPaymentWebView = true
    }
    
    func handlePaymentResult(_ result: PaymentWebView.PaymentResult) {
        self.showingPaymentWebView = false
        
        switch result {
        case .success(let orderId):
            // The status will be updated via Realtime automatically.
            // But we can trigger a fetch to be sure.
            Task { await fetchActiveOrders() }
        case .failure(let message):
            self.errorMessage = message
        }
    }
}
 

