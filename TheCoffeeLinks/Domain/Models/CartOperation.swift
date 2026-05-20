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
    case replaceItem(oldKey: String, item: CartItem)
    case clear
    case setMode(OrderingMode)
    case setStore(storeId: String)
    case setAddress(addressId: String)
    case setVoucher(code: String?)
    case setNotes(notes: String?)
    
    var isIdempotent: Bool {
        switch self {
        case .add, .updateQuantity: return false
        case .remove, .replaceItem, .clear, .setMode, .setStore, .setAddress, .setVoucher, .setNotes: return true
        }
    }

    var requiresServerRebuild: Bool {
        switch self {
        case .add:
            return false
        case .updateQuantity, .remove, .replaceItem, .clear, .setMode, .setStore, .setAddress, .setVoucher, .setNotes:
            return true
        }
    }
    
    // Used for deduplication
    var operationType: String {
        switch self {
        case .add: return "add"
        case .updateQuantity: return "updateQuantity"
        case .remove: return "remove"
        case .replaceItem: return "replaceItem"
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
    nonisolated mutating func applyOperation(_ operation: CartOperation) {
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
            
            // Construct a placeholder item with available data so it's tracked in the cart
            // rather than silently dropping it. The product details will be hydrated during sync.
            let placeholderProduct = Product(
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
            )
            let newItem = CartItem(
                key: key,
                product: placeholderProduct,
                quantity: quantity,
                customization: customization,
                addedAt: Date(),
                priceSnapshot: priceSnapshot,
                storeId: storeId
            )
            let previousCount = items.count
            addItem(newItem)
            if items.count > previousCount {
                debugLog("⚠️ [Cart] Added item with placeholder product — will hydrate during sync")
            }
            
        case .updateQuantity(let key, let delta):
            updateQuantity(for: key, delta: delta)
            
        case .remove(let key):
            removeItem(key)

        case .replaceItem(let oldKey, let item):
            replaceItem(oldKey: oldKey, with: item)
            
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
