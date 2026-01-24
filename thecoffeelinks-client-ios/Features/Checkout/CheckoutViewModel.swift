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
    private var undoTimer: Timer?
    private let undoWindowDuration: TimeInterval = 30
    
    init(orderRepository: OrderRepositoryProtocol, deliveryRepository: DeliveryRepositoryProtocol, voucherRepository: VoucherRepositoryProtocol,
         predictionRepository: PredictionRepositoryProtocol, analyticsService: AnalyticsServiceProtocol, hapticService: HapticServiceProtocol) {
        self.orderRepository = orderRepository
        self.deliveryRepository = deliveryRepository
        self.voucherRepository = voucherRepository
        self.predictionRepository = predictionRepository
        self.analyticsService = analyticsService
        self.hapticService = hapticService
    }
    
    func placeOrder(cart: Cart) async -> Order? {
        guard !cart.isEmpty, let storeId = cart.storeId else {
            error = CheckoutError.noStoreSelected
            return nil
        }
        
        isPlacingOrder = true; error = nil
        
        do {
            let request = CreateOrderRequest(
                storeId: storeId, mode: cart.mode, paymentMethod: paymentMethod,
                items: cart.items.map { CreateOrderItemRequest(productId: $0.product.id, productName: $0.product.name, quantity: $0.quantity, finalPrice: $0.unitPrice, customization: $0.customization) },
                tableId: cart.tableId, deliveryAddressId: cart.deliveryAddressId, deliveryNotes: cart.staffNotes, staffNotes: nil, voucherCode: cart.voucherCode, totalAmount: cart.subtotal
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
            // We can fetch the updated order or just show success.
            // For now, let's just clear errors and perhaps fetch it or assume success.
            isPlacingOrder = false
            // Note: In a real app, you might want to fetch the order now to get its definitive status.
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
