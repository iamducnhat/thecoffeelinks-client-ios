//
//  CartService.swift
//  TheCoffeeLinks
//
//  Created by AI Agent on 2026-01-27.
//

import Foundation
import Combine

protocol CartServiceProtocol {
    func getCart() async throws -> Cart
    func addToCart(productId: UUID, quantity: Int, modifiers: OrderCustomization) async throws -> Cart
    func clearCart() async throws
}

final class CartService: CartServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // MARK: - API Calls
    
    func getCart() async throws -> Cart {
        let payload = GetCartPayload(store_id: nil)
        let response: CartResponse = try await networkService.post("/api/cart", body: payload, encoder: nil)
        guard response.success, let cartData = response.cart else {
            throw CartError.failedToFetch
        }
        return mapToDomainCart(cartData)
    }
    
    func addToCart(productId: UUID, quantity: Int, modifiers: OrderCustomization) async throws -> Cart {
        let payload = AddItemPayload(product_id: productId.uuidString, quantity: quantity, modifiers: modifiers)
        let response: CartResponse = try await networkService.post("/api/cart/items", body: payload, encoder: nil)
        guard response.success, let cartData = response.cart else {
            throw CartError.failedToAdd
        }
        return mapToDomainCart(cartData)
    }
    
    func clearCart() async throws {
        // Not implemented on server yet as a single endpoint
    }
    
    // MARK: - Mappers
    
    private func mapToDomainCart(_ serverCart: ServerCart) -> Cart {
        var domainItems: [CartItem] = []
        
        for item in serverCart.items {
            if let product = mapToProduct(item.product) {
                // Parse Customization
                var customization = OrderCustomization.default
                if let mods = item.modifiers {
                    customization = mods
                }
                
                let domainItem = CartItem(
                    id: UUID(uuidString: item.id) ?? UUID(),
                    product: product,
                    quantity: item.quantity,
                    customization: customization,
                    addedAt: Date()
                )
                domainItems.append(domainItem)
            }
        }
        
        var cart = Cart.empty
        cart.items = domainItems
        cart.storeId = serverCart.store_id
        cart.voucherCode = serverCart.voucher_code
        // Note: serverCart subtotal/total should ideally be used. 
        // We rely on 'Cart' struct computed properties for now to ensure consistency with UI.
        
        return cart
    }
    
    private func mapToProduct(_ serverProduct: ServerProduct) -> Product? {
        let sizeOpts = serverProduct.size_options_list 
        
        return Product(
            id: serverProduct.id, // String
            name: serverProduct.name,
            description: serverProduct.description, // String?
            categoryId: "unknown", // Default
            categoryName: serverProduct.category, // String?
            imageUrl: serverProduct.image, // String?
            basePrice: Double(serverProduct.price ?? serverProduct.price_min ?? 0),
            sizeOptions: sizeOpts,
            availableToppings: serverProduct.available_toppings ?? [],
            isPopular: serverProduct.is_popular,
            isNew: serverProduct.is_new,
            isActive: true, // Default
            isHotSupported: false, // Default
            isDeliverable: true, // Default
            deliveryPrepMinutes: nil,
            tags: [],
            nutritionInfo: nil,
            allergens: []
        )
    }
}

// MARK: - DTOs

enum CartError: Error {
    case failedToFetch
    case failedToAdd
}

struct GetCartPayload: Encodable {
    let store_id: String?
}

struct CartResponse: Decodable {
    let success: Bool
    let cart: ServerCart?
    let error: String?
}

struct ServerCart: Decodable {
    let id: String
    let items: [ServerCartItem]
    let subtotal: Double
    let total_amount: Double
    let store_id: String?
    let voucher_code: String?
}

struct ServerCartItem: Decodable {
    let id: String
    let product_id: String
    let quantity: Int
    let modifiers: OrderCustomization?
    let price_snapshot: Double
    let product: ServerProduct
}

struct ServerProduct: Decodable {
    let id: String
    let name: String
    let description: String?
    let price: Int? 
    let price_min: Int?
    let image: String?
    let category: String?
    let is_popular: Bool
    let is_new: Bool
    let size_options: [String: ServerSizeOption]?
    let available_toppings: [String]?
    
    var size_options_list: [SizeOption] {
        guard let opts = size_options else { return [] }
        var list: [SizeOption] = []
        for (key, val) in opts {
            if let size = ProductSize(rawValue: key) ?? ProductSize(rawValue: key.uppercased()) { // "medium" -> nil? Need mapping
                 list.append(SizeOption(size: size, price: val.price, isEnabled: val.enabled))
            } else {
                // Try manual map
                let s: ProductSize
                switch key.lowercased() {
                case "s", "small": s = .small
                case "m", "medium": s = .medium
                case "l", "large": s = .large
                default: continue
                }
                list.append(SizeOption(size: s, price: val.price, isEnabled: val.enabled))
            }
        }
        return list
    }
}

struct ServerSizeOption: Decodable {
    let price: Double
    let enabled: Bool
}

struct AddItemPayload: Encodable {
    let product_id: String
    let quantity: Int
    let modifiers: OrderCustomization
}
