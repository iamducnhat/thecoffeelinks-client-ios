//
//  CartService.swift
//  TheCoffeeLinks
//
//  Created by AI Agent on 2026-01-27.
//

import Foundation
import Combine
import SwiftUI // For Task priority if needed

protocol CartServiceProtocol {
    func loadLocalCart() -> Cart?
    func fetchRemoteCart() async throws -> Cart
    func addToCart(productId: UUID, quantity: Int, modifiers: OrderCustomization) async throws -> Cart
    func addToCart(product: Product, quantity: Int, modifiers: OrderCustomization) async throws -> Cart
    func clearCart() async throws
}

final class CartService: CartServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let cartStorage: CartStorageProtocol
    
    // In-memory dirty flag or queue could be added here for robust sync manager
    
    init(networkService: NetworkServiceProtocol, cartStorage: CartStorageProtocol) {
        self.networkService = networkService
        self.cartStorage = cartStorage
    }
    
    // MARK: - Local First API
    
    func loadLocalCart() -> Cart? {
        return cartStorage.loadCart()
    }
    
    func fetchRemoteCart() async throws -> Cart {
        // Fetch from server
        let payload = GetCartPayload(store_id: nil) // Or generic fetch
        let response: CartResponse = try await networkService.post("/api/cart", body: payload, encoder: nil)
        
        guard response.success, let cartData = response.cart else {
            throw CartError.failedToFetch
        }
        
        let mappedCart = mapToDomainCart(cartData)
        
        // RECONCILE: Simple Last-Write-Wins or Server Authoritative
        // For Cart, Server is usually authoritative on Price/Availability.
        // So we overwrite local with server version.
        // Persist to disk
        try? cartStorage.saveCart(mappedCart)
        
        return mappedCart
    }
    
    func addToCart(productId: UUID, quantity: Int, modifiers: OrderCustomization) async throws -> Cart {
        // Fallback for when Product object is not available (Non-Optimistic)
        let payload = AddItemPayload(product_id: productId.uuidString, quantity: quantity, modifiers: modifiers, key: nil)
        let response: CartResponse = try await networkService.post("/api/cart/items", body: payload, encoder: nil)
        
        guard response.success, let cartData = response.cart else {
            throw CartError.failedToAdd
        }
        
        let mappedCart = mapToDomainCart(cartData)
        try? cartStorage.saveCart(mappedCart)
        return mappedCart
    }
    
    func addToCart(product: Product, quantity: Int, modifiers: OrderCustomization) async throws -> Cart {
        var currentCart = cartStorage.loadCart() ?? Cart.empty
        
        // Ensure we have a valid storeId. If the cart is empty/new, we might not have one yet.
        // Ideally the VM sets the store before adding, or we pass it here.
        // For now, we rely on the cart's existing storeId or empty string if it's a fresh implicit cart.
        let storeId = currentCart.storeId ?? ""
        
        // 1. Calculate Price Snapshot
        let priceSnapshot = product.price(for: modifiers.size) + modifiers.toppingsTotal
        
        // 2. Generate Deterministic Key
        let key = CartItem.generateKey(
            product: product, 
            modifiers: modifiers, 
            priceSnapshot: priceSnapshot, 
            storeId: storeId
        )
        
        // 3. Optimistic Update
        let newItem = CartItem(
            key: key,
            product: product,
            quantity: quantity,
            customization: modifiers,
            addedAt: Date(),
            priceSnapshot: priceSnapshot,
            storeId: storeId
        )
        
        currentCart.addItem(newItem)
        currentCart.lastUpdated = Date()
        
        // Find final quantity after merge to send to server (for upsert)
        let finalQuantity = currentCart.items.first(where: { $0.key == key })?.quantity ?? quantity
        
        // 4. Persist
        try? cartStorage.saveCart(currentCart)
        
        // 5. Background Sync
        Task {
            do {
                let payload = AddItemPayload(
                    product_id: product.id, 
                    quantity: finalQuantity, // Send Total Quantity
                    modifiers: modifiers,
                    key: key
                )
                let response: CartResponse = try await networkService.post("/api/cart/items", body: payload, encoder: nil)
                
                if response.success, let serverCartData = response.cart {
                    let serverCart = mapToDomainCart(serverCartData)
                    // Replace Local to ensure consistency
                    try? cartStorage.saveCart(serverCart)
                    // Ideally notify listeners here
                }
            } catch {
                print("Sync failed: \(error)")
            }
        }
        
        return currentCart
    }

    func clearCart() async throws {
        cartStorage.clearCart()
        // server sync logic...
    }
    
    // MARK: - Mappers
    
    private func mapToDomainCart(_ serverCart: ServerCart) -> Cart {
        var mergedItems: [String: CartItem] = [:]
        var orderedKeys: [String] = [] // To preserve server order if possible, or just stability
        
        let storeId = serverCart.store_id ?? ""
        
        for item in serverCart.items {
            if let product = mapToProduct(item.product) {
                // Parse Customization
                var customization = OrderCustomization.default
                if let mods = item.modifiers {
                    customization = mods
                }
                
                let priceSnapshot = item.price_snapshot
                let key = CartItem.generateKey(
                    product: product, 
                    modifiers: customization, 
                    priceSnapshot: priceSnapshot, 
                    storeId: storeId
                )
                
                let domainItem = CartItem(
                    key: key,
                    product: product,
                    quantity: item.quantity,
                    customization: customization,
                    addedAt: Date(), // or parse if available
                    priceSnapshot: priceSnapshot,
                    storeId: storeId
                )
                
                if var existing = mergedItems[key] {
                    // MERGE DUPLICATE FROM SERVER
                    existing.quantity += domainItem.quantity
                    mergedItems[key] = existing
                } else {
                    mergedItems[key] = domainItem
                    orderedKeys.append(key)
                }
            }
        }
        
        var cart = Cart.empty
        cart.items = orderedKeys.compactMap { mergedItems[$0] }
        cart.storeId = serverCart.store_id
        cart.voucherCode = serverCart.voucher_code
        cart.lastUpdated = Date()
        
        return cart
    }
    
    private func mapToProduct(_ serverProduct: ServerProduct) -> Product? {
        let sizeOpts = serverProduct.size_options_list 
        
        return Product(
            id: serverProduct.id,
            name: serverProduct.name,
            description: serverProduct.description ?? "",
            categoryId: "unknown",
            categoryName: serverProduct.category,
            imageUrl: serverProduct.image ?? "",
            basePrice: Double(serverProduct.price ?? serverProduct.price_min ?? 0),
            sizeOptions: sizeOpts,
            availableToppings: serverProduct.available_toppings ?? [],
            isPopular: serverProduct.is_popular,
            isNew: serverProduct.is_new,
            isActive: true,
            isHotSupported: false,
            isDeliverable: true,
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
            if let size = ProductSize(rawValue: key) ?? ProductSize(rawValue: key.uppercased()) {
                 list.append(SizeOption(size: size, price: val.price, isEnabled: val.enabled))
            } else {
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
    let key: String?
}
