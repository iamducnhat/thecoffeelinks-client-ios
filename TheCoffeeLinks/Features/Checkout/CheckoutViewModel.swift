//
//  CheckoutViewModel.swift
//  thecoffeelinks-client-ios
//
//  Checkout with 30-second undo window
//

import Foundation
import Combine

@MainActor
final class CheckoutViewModel: ObservableObject {
    @Published var paymentMethod: PaymentMethod = .applePay
    @Published var selectedAddressId: String?
    @Published var tableId: String?
    @Published var isPlacingOrder = false
    @Published var orderPlaced: Order?
    @Published var orderCancelled: Order?
    @Published var error: Error?
    @Published var undoTimeRemaining: TimeInterval = 0
    @Published var showingUndoBanner = false
    
    @Published var warning: String? // Non-blocking warning (e.g. invalid points)
    
    // VNPay Support
    @Published var showingPaymentWebView = false
    @Published var paymentUrl: URL?
    @Published var paymentResult: PaymentWebView.PaymentResult?
    
    // Applied State
    @Published var appliedPoints: Int = 0
    @Published var appliedVoucher: String?
    
    // Constants
    private let pointsRedemptionRate: Double = 1000.0 // 1 Point = 1000 VND

    
    private let orderRepository: OrderRepositoryProtocol
    private let deliveryRepository: DeliveryRepositoryProtocol
    private let voucherRepository: VoucherRepositoryProtocol
    private let predictionRepository: PredictionRepositoryProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let hapticService: HapticServiceProtocol
    private let orderStorage: OrderStorageProtocol
    
    private var undoTimerTask: Task<Void, Never>?
    private let undoWindowDuration: TimeInterval = 30
    private var cancellables = Set<AnyCancellable>()
    
    init(orderRepository: OrderRepositoryProtocol, 
         deliveryRepository: DeliveryRepositoryProtocol, 
         voucherRepository: VoucherRepositoryProtocol,
         predictionRepository: PredictionRepositoryProtocol, 
         analyticsService: AnalyticsServiceProtocol, 
         hapticService: HapticServiceProtocol,
         orderStorage: OrderStorageProtocol = OrderStorage()) {
        self.orderRepository = orderRepository
        self.deliveryRepository = deliveryRepository
        self.voucherRepository = voucherRepository
        self.predictionRepository = predictionRepository
        self.analyticsService = analyticsService
        self.hapticService = hapticService
        self.orderStorage = orderStorage
        
        loadDraft()
        setupDraftPersistence()
    }
    
    private func loadDraft() {
        if let draft = orderStorage.loadDraft() {
            self.paymentMethod = draft.paymentMethod
            self.selectedAddressId = draft.selectedAddressId
            self.tableId = draft.tableId
            // staffNotes handled via Cart, not here directly, but if moved here:
            // self.staffNotes = draft.staffNotes
        }
    }
    
    private func setupDraftPersistence() {
        Publishers.CombineLatest3($paymentMethod, $selectedAddressId, $tableId)
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] method, addressId, tableId in
                let draft = OrderDraft(paymentMethod: method, selectedAddressId: addressId, tableId: tableId, staffNotes: nil)
                self?.orderStorage.saveDraft(draft)
            }
            .store(in: &cancellables)
    }
    
    func applyVoucher(code: String, cartViewModel: CartViewModel) async {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Apply only once unless edited
        guard trimmedCode != (appliedVoucher ?? "") else { return }
        
        if trimmedCode.isEmpty { 
            cartViewModel.removeVoucher()
            appliedVoucher = nil
            return 
        }
        
        await cartViewModel.applyVoucher(code: trimmedCode)
        if let error = cartViewModel.error as? VoucherError {
             self.warning = error.localizedDescription
        } else {
            self.warning = nil
            appliedVoucher = trimmedCode
        }
    }
    
    func applyPoints(input: String, availablePoints: Int, cartViewModel: CartViewModel) {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedInput.isEmpty else {
            if appliedPoints != 0 {
                appliedPoints = 0
                cartViewModel.removePointsDiscount()
            }
            return
        }
        
        guard let points = Int(trimmedInput), points >= 0 else {
            warning = String(localized: "invalid_points_numeric")
            return
        }
        
        // Apply only once unless edited
        guard points != appliedPoints else { return }
        
        warning = nil
        
        guard points <= availablePoints else {
            warning = String(localized: "insufficient_points \(availablePoints)")
            return
        }
        
        let discount = Double(points) * pointsRedemptionRate
        
        appliedPoints = points
        cartViewModel.applyPointsDiscount(discount)
        
        Task { await hapticService.selection() }
    }
    
    func placeOrder(cart: Cart, pointsToRedeem: Int? = nil, voucherCode: String? = nil) async -> Order? {
        // Prevent double-tap creating duplicate orders
        guard !isPlacingOrder else {
            debugLog("⚠️ [CheckoutViewModel] placeOrder called while already placing — ignoring duplicate")
            return nil
        }
        
        guard !cart.isEmpty, let storeId = cart.storeId else {
            error = CheckoutError.noStoreSelected
            return nil
        }
        
        // MARK: - Pre-Checkout Validation
        // Verify all items are available at the selected store
        let unavailableItems = cart.items.filter { !$0.product.isAvailableAt(storeId: storeId) }
        if !unavailableItems.isEmpty {
            let itemNames = unavailableItems.map { $0.product.name }.joined(separator: ", ")
            error = CheckoutError.unavailableItems(itemNames)
            return nil
        }
        
        isPlacingOrder = true; error = nil
        
        do {
            // Priority: Argument > Cart > nil
            let finalVoucherCode = voucherCode?.isEmpty == false ? voucherCode : cart.voucherCode
            
            // Sanitize user-provided text to prevent XSS if rendered in staff dashboard
            let sanitizedStaffNotes = cart.staffNotes.map { Self.sanitizeNotes($0) }
            // C2 FIX: deliveryNotes uses cart.deliveryNotes (separate from staffNotes)
            let sanitizedDeliveryNotes = cart.deliveryNotes.map { Self.sanitizeNotes($0) }
            
            // C3 FIX: Generate idempotency key to prevent duplicate orders
            let idempotencyKey = UUID().uuidString
            
            let request = CreateOrderRequest(
                storeId: storeId, mode: cart.mode, paymentMethod: paymentMethod,
                items: cart.items.map { CreateOrderItemRequest(productId: $0.product.id, productName: $0.product.name, quantity: $0.quantity, finalPrice: $0.unitPrice, customization: $0.customization) },
                tableId: cart.tableId, deliveryAddressId: cart.deliveryAddressId, 
                deliveryNotes: sanitizedDeliveryNotes, 
                staffNotes: sanitizedStaffNotes, 
                voucherCode: finalVoucherCode, 
                pointsToRedeem: pointsToRedeem,
                totalAmount: cart.subtotal,
                idempotencyKey: idempotencyKey
            )
            
            let order = try await orderRepository.createOrder(request)
            
            // Handle VNPay URL if present
            if let urlString = order.paymentUrl {
                guard let url = URL(string: urlString) else {
                    // Payment URL is malformed — order exists server-side but we can't open payment.
                    // Surface error instead of silently dropping the order.
                    self.error = CheckoutError.paymentFailedWithMessage("Invalid payment URL returned by server")
                    isPlacingOrder = false
                    return nil
                }
                // Persist the pending payment order ID so we can recover if the app is killed
                UserDefaults.standard.set(order.id, forKey: "pendingPaymentOrderId")
                self.paymentUrl = url
                self.showingPaymentWebView = true
                isPlacingOrder = false
                return nil // Don't return order yet, wait for payment
            }
            
            orderPlaced = order
            orderStorage.clearDraft() // Clear draft on success
            
            await predictionRepository.recordOrder(items: cart.items, context: .current)
            await analyticsService.trackPurchase(orderId: order.id, amount: order.totalAmount, items: order.items)
            await hapticService.notification(.success)
            isPlacingOrder = false
            return order
        } catch {
            self.error = error
            await hapticService.notification(.error)
            isPlacingOrder = false
            return nil
        }
    }
    
    func cancelOrder(_ order: Order, reason: String? = nil) async {
        error = nil
        do {
            let cancelledOrder = try await orderRepository.cancelOrder(id: order.id, reason: reason)
            orderCancelled = cancelledOrder
            showingUndoBanner = true
            undoTimeRemaining = undoWindowDuration
            startUndoTimer()
            await analyticsService.trackEvent("order_cancelled", properties: ["orderId": order.id, "reason": reason ?? "none"])
            await hapticService.notification(.warning)
        } catch { self.error = error }
    }
    
    func undoCancel() async {
        guard let cancelled = orderCancelled, cancelled.canUndo else { error = OrderError.undoExpired; return }
        do {
            let restoredOrder = try await orderRepository.undoCancelOrder(id: cancelled.id)
            orderPlaced = restoredOrder
            orderCancelled = nil
            showingUndoBanner = false
            stopUndoTimer()
            await analyticsService.trackEvent("order_cancel_undone", properties: ["orderId": cancelled.id])
            await hapticService.notification(.success)
        } catch { self.error = error }
    }
    
    private func startUndoTimer() {
        stopUndoTimer()
        let startTime = Date()
        let duration = undoWindowDuration
        undoTimerTask = Task { [weak self] in
            let tickInterval: UInt64 = 100_000_000 // 0.1 seconds in nanoseconds
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: tickInterval)
                guard let self = self, !Task.isCancelled else { break }
                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = duration - elapsed
                if remaining > 0 {
                    self.undoTimeRemaining = remaining
                } else {
                    self.undoTimeRemaining = 0
                    self.showingUndoBanner = false
                    self.orderCancelled = nil
                    break
                }
            }
        }
    }
    
    private func stopUndoTimer() { 
        undoTimerTask?.cancel()
        undoTimerTask = nil 
    }
    
    // MARK: - Payment Handlers
    
    func handlePaymentResult(_ result: PaymentWebView.PaymentResult) {
        self.paymentResult = result
        self.showingPaymentWebView = false
        
        switch result {
        case .success(let orderId):
            // Success! The order is already updated on the backend.
            isPlacingOrder = false
            orderStorage.clearDraft() // Clear draft on payment success
            UserDefaults.standard.removeObject(forKey: "pendingPaymentOrderId") // Clear pending payment
            
            Task {
                do {
                    let updatedOrder = try await orderRepository.getOrder(id: orderId)
                    orderPlaced = updatedOrder
                    await analyticsService.trackPurchase(orderId: orderId, amount: updatedOrder.totalAmount, items: updatedOrder.items)
                    await hapticService.notification(.success)
                } catch {
                    // Retry once — network blip during VNPay callback is common
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
                    do {
                        let retryOrder = try await orderRepository.getOrder(id: orderId)
                        orderPlaced = retryOrder
                        await analyticsService.trackPurchase(orderId: orderId, amount: retryOrder.totalAmount, items: retryOrder.items)
                        await hapticService.notification(.success)
                    } catch {
                        self.error = error
                    }
                }
            }
        case .failure(let message):
            self.error = CheckoutError.paymentFailedWithMessage(message)
            Task {
                await hapticService.notification(.error)
            }
        }
    }
    // MARK: - Pending Payment Recovery
    
    /// Call on app launch to recover from app-killed-mid-payment scenario.
    /// If a pending payment order ID exists, fetch it and show the result.
    func recoverPendingPaymentIfNeeded() async {
        guard let pendingOrderId = UserDefaults.standard.string(forKey: "pendingPaymentOrderId") else { return }
        
        do {
            let order = try await orderRepository.getOrder(id: pendingOrderId)
            UserDefaults.standard.removeObject(forKey: "pendingPaymentOrderId")
            
            // If payment was completed while app was killed, show success
            // Valid "paid" statuses: .received (store acknowledged), .preparing, .ready, .completed
            if order.status == .received || order.status == .preparing || order.status == .ready || order.status == .completed {
                orderPlaced = order
            }
            // If still pending payment, the user can retry or it will expire server-side
        } catch {
            debugLog("⚠️ [CheckoutViewModel] Failed to recover pending payment order: \(error)")
            // Don't remove the key — will retry on next launch
        }
    }
    
    // MARK: - Input Sanitization
    
    /// Strip HTML/script tags and limit length to prevent XSS if rendered in staff dashboard
    private static func sanitizeNotes(_ input: String) -> String {
        var sanitized = input
        // Remove HTML tags
        sanitized = sanitized.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Remove common script injection patterns
        sanitized = sanitized.replacingOccurrences(of: "javascript:", with: "", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "on\\w+=", with: "", options: .regularExpression)
        // Trim and limit length
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.count > 500 { sanitized = String(sanitized.prefix(500)) }
        return sanitized
    }
}

enum CheckoutError: LocalizedError {
    case noStoreSelected, deliveryAddressRequired, minimumNotMet(Double), paymentFailed, paymentFailedWithMessage(String), unavailableItems(String)
    var errorDescription: String? {
        switch self {
        case .noStoreSelected: return "Please select a store"
        case .deliveryAddressRequired: return "Please select a delivery address"
        case .minimumNotMet(let amount): return "Minimum order amount is \(amount.formattedVND)"
        case .paymentFailed: return "Payment failed. Please try again."
        case .paymentFailedWithMessage(let msg): return msg
        case .unavailableItems(let items): return "These items are not available at the selected store: \(items)"
        }
    }
}

