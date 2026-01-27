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
    private let productRepository: ProductRepositoryProtocol
    
    // In-memory dirty flag or queue could be added here for robust sync manager
    
    init(networkService: NetworkServiceProtocol, cartStorage: CartStorageProtocol, productRepository: ProductRepositoryProtocol) {
        self.networkService = networkService
        self.cartStorage = cartStorage
        self.productRepository = productRepository
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
        
        // Hydrate from product repository
        let mappedCart = try await mapToDomainCart(cartData)
        
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
        
        let mappedCart = try await mapToDomainCart(cartData)
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
                    let serverCart = try await mapToDomainCart(serverCartData)
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
    
    private func mapToDomainCart(_ serverCart: ServerCart) async throws -> Cart {
        var mergedItems: [String: CartItem] = [:]
        var orderedKeys: [String] = [] // To preserve server order if possible, or just stability
        
        // Fetch full menu to resolve products
        // This is efficient because getMenu() caches aggressively
        let menu = try await productRepository.getMenu()
        let productsMap = Dictionary(uniqueKeysWithValues: menu.products.map { ($0.id, $0) })
        
        let storeId = serverCart.store_id ?? ""
        
        for item in serverCart.items {
            if let product = productsMap[item.product_id] {
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
    
    enum CodingKeys: String, CodingKey {
        case id, items, subtotal, total_amount, store_id, voucher_code
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        
        // Robust decoding: Skip invalid items instead of failing the whole cart
        let safeItems = try container.decode([SafeDecodable<ServerCartItem>].self, forKey: .items)
        items = safeItems.compactMap { $0.value }
        
        subtotal = try container.decode(Double.self, forKey: .subtotal)
        total_amount = try container.decode(Double.self, forKey: .total_amount)
        store_id = try container.decodeIfPresent(String.self, forKey: .store_id)
        voucher_code = try container.decodeIfPresent(String.self, forKey: .voucher_code)
    }
}

struct ServerCartItem: Decodable {
    let id: String
    let product_id: String
    let quantity: Int
    let modifiers: OrderCustomization?
    let price_snapshot: Double
}



struct AddItemPayload: Encodable {
    let product_id: String
    let quantity: Int
    let modifiers: OrderCustomization
    let key: String?
}

// MARK: - Safe Decoding

struct SafeDecodable<T: Decodable>: Decodable {
    let value: T?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try? container.decode(T.self)
    }
}
