//
//  CartOperation.swift
//  TheCoffeeLinks
//
//  Cart operation types for queue-based sync
//

import Foundation

enum CartOperation: Codable, Equatable {
    case add(productId: String, quantity: Int, customization: OrderCustomization, priceSnapshot: Double, storeId: String)
    case updateQuantity(key: String, delta: Int)
    case remove(key: String)
    case clear
    case setMode(OrderingMode)
    case setStore(storeId: String)
    case setAddress(addressId: String)
    case setVoucher(code: String?)
    case setNotes(notes: String?)
    
    var isIdempotent: Bool {
        switch self {
        case .add, .updateQuantity: return false
        case .remove, .clear, .setMode, .setStore, .setAddress, .setVoucher, .setNotes: return true
        }
    }
    
    // Used for deduplication
    var operationType: String {
        switch self {
        case .add: return "add"
        case .updateQuantity: return "updateQuantity"
        case .remove: return "remove"
        case .clear: return "clear"
        case .setMode: return "setMode"
        case .setStore: return "setStore"
        case .setAddress: return "setAddress"
        case .setVoucher: return "setVoucher"
        case .setNotes: return "setNotes"
        }
    }
}

extension Cart {
    mutating func applyOperation(_ operation: CartOperation) {
        switch operation {
        case .add(let productId, let quantity, let customization, let priceSnapshot, let storeId):
            // Generate key
            let key = CartItem.generateKey(
                product: Product(
                    id: productId,
                    name: "",
                    description: nil,
                    categoryId: "",
                    categoryName: nil,
                    imageUrl: nil,
                    basePrice: priceSnapshot,
                    sizeOptions: [],
                    availableToppings: [],
                    isPopular: false,
                    isNew: false,
                    isActive: true,
                    isHotSupported: false,
                    isDeliverable: true,
                    deliveryPrepMinutes: nil,
                    tags: [],
                    nutritionInfo: nil,
                    allergens: []
                ),
                modifiers: customization,
                priceSnapshot: priceSnapshot,
                storeId: storeId
            )
            
            if let existingIndex = items.firstIndex(where: { $0.key == key }) {
                items[existingIndex].quantity += quantity
            } else {
                // Can't fully construct item without product details
                // This operation requires product lookup during sync
                print("⚠️ Add operation requires product details for full cart item")
            }
            
        case .updateQuantity(let key, let delta):
            guard let index = items.firstIndex(where: { $0.key == key }) else { return }
            let newQuantity = items[index].quantity + delta
            if newQuantity <= 0 {
                items.remove(at: index)
            } else {
                items[index].quantity = newQuantity
            }
            
        case .remove(let key):
            items.removeAll { $0.key == key }
            
        case .clear:
            items.removeAll()
            voucherCode = nil
            staffNotes = nil
            
        case .setMode(let mode):
            self.mode = mode
            
        case .setStore(let storeId):
            self.storeId = storeId
            
        case .setAddress(let addressId):
            self.deliveryAddressId = addressId
            
        case .setVoucher(let code):
            self.voucherCode = code
            
        case .setNotes(let notes):
            self.staffNotes = notes
        }
        
        self.lastUpdated = Date()
    }
}
