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
    
    // VNPay Support
    @Published var showingPaymentWebView = false
    @Published var paymentUrl: URL?
    @Published var paymentResult: PaymentWebView.PaymentResult?
    
    private let orderRepository: OrderRepositoryProtocol
    private let deliveryRepository: DeliveryRepositoryProtocol
    private let voucherRepository: VoucherRepositoryProtocol
    private let predictionRepository: PredictionRepositoryProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let hapticService: HapticServiceProtocol
    private let orderStorage: OrderStorageProtocol
    
    private var undoTimer: Timer?
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
    
    func placeOrder(cart: Cart, pointsToRedeem: Int? = nil, voucherCode: String? = nil) async -> Order? {
        guard !cart.isEmpty, let storeId = cart.storeId else {
            error = CheckoutError.noStoreSelected
            return nil
        }
        
        isPlacingOrder = true; error = nil
        
        do {
            // Priority: Argument > Cart > nil
            let finalVoucherCode = voucherCode?.isEmpty == false ? voucherCode : cart.voucherCode
            
            let request = CreateOrderRequest(
                storeId: storeId, mode: cart.mode, paymentMethod: paymentMethod,
                items: cart.items.map { CreateOrderItemRequest(productId: $0.product.id, productName: $0.product.name, quantity: $0.quantity, finalPrice: $0.unitPrice, customization: $0.customization) },
                tableId: cart.tableId, deliveryAddressId: cart.deliveryAddressId, deliveryNotes: cart.staffNotes, staffNotes: nil, 
                voucherCode: finalVoucherCode, 
                pointsToRedeem: pointsToRedeem,
                totalAmount: cart.subtotal
            )
            
            let order = try await orderRepository.createOrder(request)
            
            // Handle VNPay URL if present
            if let urlString = order.paymentUrl, let url = URL(string: urlString) {
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
        undoTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.undoTimeRemaining > 0 { self.undoTimeRemaining -= 0.1 }
                else { self.showingUndoBanner = false; self.orderCancelled = nil; self.stopUndoTimer() }
            }
        }
    }
    
    private func stopUndoTimer() { undoTimer?.invalidate(); undoTimer = nil }
    deinit { undoTimer?.invalidate() }
    
    // MARK: - Payment Handlers
    
    func handlePaymentResult(_ result: PaymentWebView.PaymentResult) {
        self.paymentResult = result
        self.showingPaymentWebView = false
        
        switch result {
        case .success(let orderId):
            // Success! The order is already updated on the backend.
            isPlacingOrder = false
            orderStorage.clearDraft() // Clear draft on payment success
            
            Task {
                do {
                    let updatedOrder = try await orderRepository.getOrder(id: orderId)
                    orderPlaced = updatedOrder
                    await analyticsService.trackPurchase(orderId: orderId, amount: updatedOrder.totalAmount, items: updatedOrder.items)
                    await hapticService.notification(.success)
                } catch {
                    self.error = error
                }
            }
        case .failure(let message):
            self.error = CheckoutError.paymentFailedWithMessage(message)
            Task {
                await hapticService.notification(.error)
            }
        }
    }
}

enum CheckoutError: LocalizedError {
    case noStoreSelected, deliveryAddressRequired, minimumNotMet(Double), paymentFailed, paymentFailedWithMessage(String)
    var errorDescription: String? {
        switch self {
        case .noStoreSelected: return "Please select a store"
        case .deliveryAddressRequired: return "Please select a delivery address"
        case .minimumNotMet(let amount): return "Minimum order amount is \(amount.formattedVND)"
        case .paymentFailed: return "Payment failed. Please try again."
        case .paymentFailedWithMessage(let msg): return msg
        }
    }
}

