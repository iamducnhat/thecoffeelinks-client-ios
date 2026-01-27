//
//  CartViewModel.swift
//  thecoffeelinks-client-ios
//
//  Cart management with delivery fee calculations
//

import Foundation
import Combine

@MainActor
final class CartViewModel: ObservableObject {
    @Published var cart: Cart = .empty
    @Published var deliveryFee: Double = 0
    @Published var discount: Double = 0
    @Published var voucherValidation: VoucherValidation?
    @Published var deliveryAvailability: DeliveryAvailability?
    @Published var isValidatingVoucher = false
    @Published var isLoadingDelivery = false
    @Published var error: Error?
    @Published var selectedAddress: DeliveryAddress?
    
    private let deliveryRepository: DeliveryRepositoryProtocol
    private let voucherRepository: VoucherRepositoryProtocol
    private let hapticService: HapticServiceProtocol
    private let cartService: CartServiceProtocol
    
    init(deliveryRepository: DeliveryRepositoryProtocol, voucherRepository: VoucherRepositoryProtocol, hapticService: HapticServiceProtocol, cartService: CartServiceProtocol) {
        self.deliveryRepository = deliveryRepository
        self.voucherRepository = voucherRepository
        self.hapticService = hapticService
        self.cartService = cartService
        
        // 1. Load Local Immediately
        if let localCart = cartService.loadLocalCart() {
            self.cart = localCart
        }
        
        // 2. Background Fetch & Reconcile
        Task(priority: .userInitiated) { await bootstrapCart() }
    }
    
    // ... Computed variable omitted (isEmpty, itemCount, subtotal, total, summary, canCheckout) - unchanged
    // Re-declare them if replace_file_content requires context or I'm replacing init block only. 
    // I need to use StartLine/EndLine carefully.
    // I'll replace init + fetchCart + addItem to ensure full context switch.
    
    var isEmpty: Bool { cart.isEmpty }
    var itemCount: Int { cart.itemCount }
    var subtotal: Double { cart.subtotal }
    
    var total: Double {
        var amount = subtotal
        if cart.mode == .delivery { amount += deliveryFee }
        amount -= discount
        return max(0, amount)
    }
    
    var summary: CartSummary {
        let minAmount = deliveryAvailability?.minOrderAmount ?? 0
        let remaining = max(0, minAmount - subtotal)
        return CartSummary(subtotal: subtotal, deliveryFee: cart.mode == .delivery ? deliveryFee : 0, discount: discount,
                          total: total, itemCount: itemCount, meetsMinimum: subtotal >= minAmount,
                          minimumOrderAmount: minAmount, remainingForMinimum: remaining)
    }
    
    var canCheckout: Bool {
        guard !isEmpty else { return false }
        if cart.mode == .delivery {
            guard cart.deliveryAddressId != nil else { return false }
            guard deliveryAvailability?.available ?? false else { return false }
            guard summary.meetsMinimum else { return false }
        }
        guard cart.storeId != nil else { return false }
        return true
    }
    
    func bootstrapCart() async {
        do {
            let remoteCart = try await cartService.fetchRemoteCart()
            await MainActor.run {
                // Determine conflict resolution (Server Wins usually, or based on lastUpdated)
                // For now, simple replacement as server is authoritative for pricing
                self.cart = remoteCart
            }
        } catch {
            print("Background fetch failed: \(error) - keeping local")
        }
    }
    
    func fetchCart() async {
       await bootstrapCart()
    }
    
    // Legacy support via Product
    func addItem(_ item: CartItem) {
        // Wrapper to call product version
        addItem(product: item.product, quantity: item.quantity, customization: item.customization)
    }
    
    func addItem(product: Product, quantity: Int, customization: OrderCustomization) {
        Task {
            do {
                // Optimistic Update: Service updates local storage and returns immediately
                // UI updates instantly < 16ms because disk I/O is fast enough on modern iOS
                let updatedCart = try await cartService.addToCart(product: product, quantity: quantity, modifiers: customization)
                await MainActor.run {
                    self.cart = updatedCart
                }
                await hapticService.impact(.medium)
            } catch {
                await MainActor.run { self.error = error }
            }
        }
    }
    
    func updateItem(id: String, quantity: Int, customization: OrderCustomization) {
        // Local update for responsive UI, ideally sync
        if let index = cart.items.firstIndex(where: { $0.id == id }) {
            var item = cart.items[index]
            item.quantity = quantity
            item.customization = customization
            cart.items[index] = item
            Task { await hapticService.selection() }
        }
    }
    
    func updateQuantity(for itemId: String, delta: Int) {
        cart.updateQuantity(for: itemId, delta: delta)
        Task { await hapticService.selection() }
    }
    
    func removeItem(_ itemId: String) {
        cart.removeItem(itemId)
        Task { await hapticService.notification(.warning) }
    }
    
    func clearCart() { 
        cart.clear(); discount = 0; voucherValidation = nil; selectedAddress = nil 
        Task { try? await cartService.clearCart() }
    }
    func setMode(_ mode: OrderingMode) { cart.mode = mode; if mode != .delivery { deliveryFee = 0; deliveryAvailability = nil; selectedAddress = nil } }
    func setStore(_ storeId: String) { cart.storeId = storeId }
    func setDeliveryAddress(_ addressId: String, address: DeliveryAddress?) { 
        cart.deliveryAddressId = addressId
        selectedAddress = address
        if address != nil { Task { await checkDeliveryAvailability() } }
    }
    func setStaffNotes(_ notes: String) { cart.staffNotes = notes.isEmpty ? nil : notes }
    
    func checkDeliveryAvailability() async {
        guard let storeId = cart.storeId else { return }
        isLoadingDelivery = true; error = nil
        do {
            let availability = try await deliveryRepository.checkAvailability(addressId: cart.deliveryAddressId, latitude: nil, longitude: nil, storeId: storeId)
            deliveryAvailability = availability
            deliveryFee = availability.fee?.amount ?? 0
            if !availability.available { error = DeliveryError.unavailable(availability.unavailableReason?.message ?? "Delivery unavailable") }
        } catch { self.error = error }
        isLoadingDelivery = false
    }
    
    func applyVoucher(code: String) async {
        guard !code.isEmpty else { return }
        isValidatingVoucher = true; error = nil
        do {
            let validation = try await voucherRepository.validateVoucher(code: code, subtotal: subtotal, mode: cart.mode)
            voucherValidation = validation
            if validation.valid { cart.voucherCode = code; discount = validation.discountAmount; await hapticService.notification(.success) }
            else { error = VoucherError.invalid(validation.message ?? "Invalid voucher"); await hapticService.notification(.error) }
        } catch { self.error = error; await hapticService.notification(.error) }
        isValidatingVoucher = false
    }
    
    func removeVoucher() { cart.voucherCode = nil; voucherValidation = nil; discount = 0 }
}

enum VoucherError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { switch self { case .invalid(let msg): return msg } }
}
