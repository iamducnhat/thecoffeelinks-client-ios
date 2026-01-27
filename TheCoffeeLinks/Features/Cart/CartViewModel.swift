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
        
        Task { await fetchCart() }
    }
    
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
    
    func fetchCart() async {
        do {
            let fetchedCart = try await cartService.getCart()
            await MainActor.run {
                self.cart = fetchedCart
            }
        } catch {
            print("Failed to fetch cart: \(error)")
        }
    }
    
    func addItem(_ item: CartItem) {
        // Legacy: Should not be used directly if possible, or wrap
        // Assume this calls product version
        Task {
            do {
                let updatedCart = try await cartService.addToCart(productId: UUID(uuidString: item.product.id) ?? UUID(), quantity: item.quantity, modifiers: item.customization)
                 await MainActor.run {
                     self.cart = updatedCart
                     self.discount = updatedCart.voucherCode != nil ? 1 : 0 // Placeholder: Server calculates discount but we need to map it back or rely on server totals
                 }
                await hapticService.impact(.medium)
            } catch {
                self.error = error
            }
        }
    }
    
    func addItem(product: Product, quantity: Int, customization: OrderCustomization) {
        Task {
            do {
                let updatedCart = try await cartService.addToCart(productId: UUID(uuidString: product.id) ?? UUID(), quantity: quantity, modifiers: customization)
                await MainActor.run {
                    self.cart = updatedCart
                }
                await hapticService.impact(.medium)
            } catch {
                await MainActor.run { self.error = error }
            }
        }
    }
    
    func updateItem(id: UUID, quantity: Int, customization: OrderCustomization) {
        // Local update for responsive UI, ideally sync
        if let index = cart.items.firstIndex(where: { $0.id == id }) {
            var item = cart.items[index]
            item.quantity = quantity
            item.customization = customization
            cart.items[index] = item
            Task { await hapticService.selection() }
        }
    }
    
    func updateQuantity(for itemId: UUID, delta: Int) {
        cart.updateQuantity(for: itemId, delta: delta)
        Task { await hapticService.selection() }
    }
    
    func removeItem(_ itemId: UUID) {
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
