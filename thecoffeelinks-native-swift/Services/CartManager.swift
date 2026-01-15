import Foundation
import Combine

@MainActor
class CartManager: ObservableObject {
    static let shared = CartManager()
    
    @Published var items: [CartItem] = []
    
    // Delivery preferences
    @Published var selectedDeliveryOption: DeliveryOption = .takeAway
    @Published var selectedStoreId: String?
    @Published var deliveryAddress: String = ""
    @Published var deliveryNotes: String = ""
    @Published var deliveryFee: Double = 0
    @Published var minimumOrderAmount: Double = 0
    
    private init() {}
    
    var subtotal: Double {
        items.reduce(0) { $0 + ($1.finalPrice * Double($1.quantity)) }
    }
    
    var totalAmount: Double {
        var total = subtotal
        if selectedDeliveryOption == .delivery {
            total += deliveryFee
        }
        return total
    }
    
    var meetsDeliveryMinimum: Bool {
        if selectedDeliveryOption != .delivery { return true }
        return subtotal >= minimumOrderAmount
    }
    
    var remainingForFreeDelivery: Double {
        max(0, minimumOrderAmount - subtotal)
    }
    
    var totalItemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    // MARK: - Item Merging
    
    /// Check if two items have identical traits (product, customization)
    private func haveSameTraits(_ item1: CartItem, _ item2: CartItem) -> Bool {
        // Check if same product
        guard item1.product.id == item2.product.id else { return false }
        
        // Check if customizations are identical
        let custom1 = item1.customization
        let custom2 = item2.customization
        
        return custom1.size == custom2.size &&
               custom1.ice == custom2.ice &&
               custom1.sugar == custom2.sugar &&
               custom1.toppings == custom2.toppings &&
               abs(item1.finalPrice - item2.finalPrice) < 0.01 // Use small epsilon for Double comparison
    }
    
    /// Consolidates all duplicate items in the cart by merging items with identical traits
    private func consolidateItems() {
        var consolidated: [CartItem] = []
        
        for item in items {
            if let existingIndex = consolidated.firstIndex(where: { haveSameTraits($0, item) }) {
                // Merge with existing consolidated item
                let existing = consolidated[existingIndex]
                let merged = CartItem(
                    id: existing.id,
                    product: existing.product,
                    quantity: existing.quantity + item.quantity,
                    finalPrice: existing.finalPrice,
                    customization: existing.customization
                )
                consolidated[existingIndex] = merged
            } else {
                // Add as new consolidated item
                consolidated.append(item)
            }
        }
        
        items = consolidated
    }
    
    // MARK: - Cart Operations
    
    func addToCart(product: Product, quantity: Int, finalPrice: Double, customization: OrderCustomization) {
        let newItem = CartItem(
            id: UUID(),
            product: product,
            quantity: quantity,
            finalPrice: finalPrice,
            customization: customization
        )
        
        items.append(newItem)
        consolidateItems()
    }
    
    func updateCart(item: CartItem, quantity: Int, finalPrice: Double, customization: OrderCustomization) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let updated = CartItem(
                id: items[index].id,
                product: items[index].product,
                quantity: quantity,
                finalPrice: finalPrice,
                customization: customization
            )
            items[index] = updated
            consolidateItems()
        }
    }
    
    func updateQuantity(item: CartItem, delta: Int) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let newQuantity = items[index].quantity + delta
            if newQuantity > 0 {
                items[index].quantity = newQuantity
            } else {
                removeFromCart(item: item)
            }
        }
    }
    
    func removeFromCart(item: CartItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
    }
    
    func clearCart() {
        items.removeAll()
        deliveryNotes = ""
        voucherCode = ""
        discountAmount = 0
    }
    
    // MARK: - Vouchers
    @Published var voucherCode: String = ""
    @Published var discountAmount: Double = 0
    @Published var voucherError: String?
    
    func applyVoucher(_ code: String) async {
        guard !code.isEmpty else { return }
        
        // Mock validation
        await MainActor.run {
            if code.lowercased() == "coffee10" {
                discountAmount = totalAmount * 0.1
                voucherError = nil
            } else {
                discountAmount = 0
                voucherError = "Invalid voucher code"
            }
        }
    }
    
    // MARK: - Checkout
    @Published var isPlacingOrder = false
    @Published var checkoutError: String?
    
    func placeOrder() async -> Bool {
        guard !items.isEmpty else { return false }
        
        isPlacingOrder = true
        checkoutError = nil
        
        do {
            // Validate Payment Method
            if selectedDeliveryOption == .delivery {
                if deliveryAddress.isEmpty {
                    throw NSError(domain: "Cart", code: 400, userInfo: [NSLocalizedDescriptionKey: "Delivery address required"])
                }
                if !meetsDeliveryMinimum {
                     throw NSError(domain: "Cart", code: 400, userInfo: [NSLocalizedDescriptionKey: "Order is below minimum for delivery"])
                }
            }
            
            let type = selectedDeliveryOption == .dineIn ? "dine_in" : (selectedDeliveryOption == .delivery ? "delivery" : "take_away")
            let paymentMethod = "apple_pay" 
            
            // Record order for Quick Order "Your Usual" algorithm
            let itemsToRecord = items
            
            let finalTotal = totalAmount - discountAmount // totalAmount now includes deliveryFee
            
            let orderId = try await OrderRepository.shared.createOrder(
                items: items,
                total: finalTotal,
                type: type,
                tableId: "T12", // Placeholder as per prompt
                paymentMethod: paymentMethod,
                deliveryAddress: selectedDeliveryOption == .delivery ? deliveryAddress : nil,
                deliveryNotes: selectedDeliveryOption == .delivery ? deliveryNotes : nil,
                deliveryFee: selectedDeliveryOption == .delivery ? deliveryFee : 0
            )
            
            print("Order Placed: \(orderId)")
            
            // Record for Quick Order Service
            await MainActor.run {
                QuickOrderService.shared.recordOrder(items: itemsToRecord)
                QuickOrderService.shared.updateStreak()
            }
            
            clearCart()
            isPlacingOrder = false
            return true
        } catch {
            print("Checkout error: \(error)")
            checkoutError = error.localizedDescription
            isPlacingOrder = false
            return false
        }
    }
}
