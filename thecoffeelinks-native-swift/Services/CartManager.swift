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
    
    private init() {}
    
    var totalAmount: Double {
        items.reduce(0) { $0 + ($1.finalPrice * Double($1.quantity)) }
    }
    
    func addToCart(product: Product, quantity: Int, finalPrice: Double, customization: OrderCustomization) {
        let item = CartItem(
            id: UUID(),
            product: product,
            quantity: quantity,
            finalPrice: finalPrice,
            customization: customization
        )
        items.append(item)
    }
    
    func updateCart(item: CartItem, quantity: Int, finalPrice: Double, customization: OrderCustomization) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].quantity = quantity
            items[index].finalPrice = finalPrice
            items[index].customization = customization
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
        // Keep address/option potentially
    }
    
    // MARK: - Checkout
    @Published var isPlacingOrder = false
    @Published var checkoutError: String?
    
    func placeOrder() async -> Bool {
        guard !items.isEmpty else { return false }
        
        isPlacingOrder = true
        checkoutError = nil
        
        do {
            let type = selectedDeliveryOption == .dineIn ? "dine_in" : "take_away"
            // For now, hardcode tableId or paymentMethod or expose them as properties
            let paymentMethod = "apple_pay" 
            
            let orderId = try await OrderRepository.shared.createOrder(
                items: items,
                total: totalAmount,
                type: type,
                tableId: "T12", // Placeholder as per prompt
                paymentMethod: paymentMethod
            )
            
            print("Order Placed: \(orderId)")
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
