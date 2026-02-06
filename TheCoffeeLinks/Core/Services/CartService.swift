//
//  CartService.swift
//  TheCoffeeLinks
//
//  Cart service with operation queue for reliable sync
//

import Foundation
import Combine
import SwiftUI

protocol CartServiceProtocol {
    func loadLocalCart() -> Cart?
    func fetchRemoteCart() async throws -> Cart
    func addToCart(productId: UUID, quantity: Int, modifiers: OrderCustomization) async throws -> Cart
    func addToCart(product: Product, quantity: Int, modifiers: OrderCustomization) async throws -> Cart
    func clearCart() async throws
    func getOperationQueueSize() -> Int
}

final class CartService: CartServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private nonisolated(unsafe) let cartStorage: CartStorageProtocol
    private let productRepository: ProductRepositoryProtocol
    private let keychainManager: KeychainManager
    
    // Operation queue for reliable sync
    private let syncQueue = DispatchQueue(label: "com.thecoffeelinks.cart.sync", qos: .userInitiated)
    private nonisolated(unsafe) var pendingOperations: [CartOperation] = []
    private nonisolated(unsafe) var isSyncing = false
    private nonisolated(unsafe) var syncTask: Task<Void, Never>?
    private let syncDebounceInterval: TimeInterval = 0.5
    
    // Notification for sync failures
    static let syncFailedNotification = Notification.Name("CartSyncFailed")
    static let syncSuccessNotification = Notification.Name("CartSyncSuccess")
    
    init(networkService: NetworkServiceProtocol, cartStorage: CartStorageProtocol, productRepository: ProductRepositoryProtocol, keychainManager: KeychainManager) {
        self.networkService = networkService
        self.cartStorage = cartStorage
        self.productRepository = productRepository
        self.keychainManager = keychainManager
    }
    
    // MARK: - Public API
    
    func loadLocalCart() -> Cart? {
        return cartStorage.loadCart()
    }
    
    func fetchRemoteCart() async throws -> Cart {
        // 0. Auth guard - return empty cart if not authenticated
        guard keychainManager.getAccessToken() != nil else {
            print("⏭️ [CartService] No access token, returning empty cart")
            return .empty
        }
        
        // 1. Check for pending local changes
        if syncQueue.sync(execute: { !pendingOperations.isEmpty }) {
            print("⚠️ [CartService] Pending operations exist, syncing first...")
            await performSync()
        }
        
        // 2. Fetch from server
        let payload = GetCartPayload(store_id: nil)
        let response: CartResponse = try await networkService.post("/api/cart", body: payload, encoder: nil)
        
        guard response.success, let cartData = response.cart else {
            throw CartError.failedToFetch
        }
        
        // 3. Hydrate from product repository
        var mappedCart = try await mapToDomainCart(cartData)
        
        // 4. Mark clean and persist
        mappedCart.isDirty = false
        try? cartStorage.saveCart(mappedCart)
        
        return mappedCart
    }
    
    func addToCart(product: Product, quantity: Int, modifiers: OrderCustomization) async throws -> Cart {
        return try await withCheckedThrowingContinuation { continuation in
            syncQueue.async {
                do {
                    // 1. Load current cart
                    var cart = self.cartStorage.loadCart() ?? .empty
                    let storeId = cart.storeId ?? ""
                    
                    // 2. Calculate price snapshot
                    let priceSnapshot = product.price(for: modifiers.size) + modifiers.toppingsTotal
                    
                    // 3. Generate key
                    let key = CartItem.generateKey(
                        product: product,
                        modifiers: modifiers,
                        priceSnapshot: priceSnapshot,
                        storeId: storeId
                    )
                    
                    // 4. Create new item
                    let newItem = CartItem(
                        key: key,
                        product: product,
                        quantity: quantity,
                        customization: modifiers,
                        addedAt: Date(),
                        priceSnapshot: priceSnapshot,
                        storeId: storeId
                    )
                    
                    // 5. Apply optimistic update
                    cart.addItem(newItem)
                    cart.lastUpdated = Date()
                    cart.isDirty = true
                    
                    // 6. Persist optimistically
                    try? self.cartStorage.saveCart(cart)
                    
                    // 7. Queue operation
                    let operation = CartOperation.add(
                        productId: product.id,
                        quantity: quantity,
                        customization: modifiers,
                        priceSnapshot: priceSnapshot,
                        storeId: storeId
                    )
                    self.pendingOperations.append(operation)
                    
                    // 8. Return immediately for responsive UI
                    continuation.resume(returning: cart)
                    
                    // 9. Schedule debounced sync
                    self.scheduleSyncIfNeeded()
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func addToCart(productId: UUID, quantity: Int, modifiers: OrderCustomization) async throws -> Cart {
        // Fallback for when Product object is not available
        let payload = AddItemPayload(product_id: productId.uuidString, quantity: quantity, modifiers: modifiers, key: nil)
        let response: CartResponse = try await networkService.post("/api/cart/items", body: payload, encoder: nil)
        
        guard response.success, let cartData = response.cart else {
            throw CartError.failedToAdd
        }
        
        let mappedCart = try await mapToDomainCart(cartData)
        try? cartStorage.saveCart(mappedCart)
        return mappedCart
    }
    
    func clearCart() async throws {
        syncQueue.sync {
            pendingOperations.removeAll()
            pendingOperations.append(.clear)
        }
        
        cartStorage.clearCart()
        await performSync()
    }
    
    func getOperationQueueSize() -> Int {
        syncQueue.sync { pendingOperations.count }
    }
    
    // MARK: - Sync Logic
    
    private nonisolated func scheduleSyncIfNeeded() {
        // Cancel existing task
        syncTask?.cancel()
        
        // Schedule new debounced sync
        syncTask = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(syncDebounceInterval * 1_000_000_000))
                await performSync()
            } catch {
                // Task cancelled - normal
            }
        }
    }
    
    private func performSync() async {
        // Prevent concurrent syncs
        guard !isSyncing else {
            print("⚠️ [CartService] Sync already in progress")
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Get operations to sync
        let operations = syncQueue.sync {
            let ops = self.pendingOperations
            self.pendingOperations.removeAll()
            return ops
        }
        
        guard !operations.isEmpty else { return }
        
        print("🔄 [CartService] Syncing \(operations.count) operations...")
        
        do {
            // Batch sync operations
            let serverCart = try await syncOperations(operations)
            
            // Check for new operations that arrived during sync
            let newOperations = syncQueue.sync { self.pendingOperations }
            
            // Merge server state with new local operations
            var finalCart = serverCart
            for op in newOperations {
                finalCart.applyOperation(op)
            }
            
            finalCart.isDirty = !newOperations.isEmpty
            try? cartStorage.saveCart(finalCart)
            
            print("✅ [CartService] Sync completed successfully")
            NotificationCenter.default.post(name: Self.syncSuccessNotification, object: nil)
            
        } catch {
            print("❌ [CartService] Sync failed: \(error)")
            
            // Re-queue failed operations
            syncQueue.async {
                self.pendingOperations.insert(contentsOf: operations, at: 0)
            }
            
            // Notify UI
            NotificationCenter.default.post(name: Self.syncFailedNotification, object: error)
        }
    }
    
    private func syncOperations(_ operations: [CartOperation]) async throws -> Cart {
        // For now, implement simple strategy: send all items to server
        // Server should handle upsert/merge logic
        
        var cart = cartStorage.loadCart() ?? .empty
        
        // Apply all operations locally first to get target state
        for operation in operations {
            cart.applyOperation(operation)
        }
        
        // Sync with server by sending full cart state
        // This is simpler than sending individual operations
        // but less efficient - can be optimized later
        
        if operations.contains(where: { $0.operationType == "clear" }) {
            // Clear on server
            try await networkService.delete("/api/cart", queryItems: nil)
            return .empty
        }
        
        // For adds/updates, send items to server
        for item in cart.items {
            let payload = AddItemPayload(
                product_id: item.product.id,
                quantity: item.quantity,
                modifiers: item.customization,
                key: item.key
            )
            _ = try await networkService.post("/api/cart/items", body: payload, encoder: nil) as CartResponse
        }
        
        // Fetch final state from server
        return try await fetchRemoteCart()
    }
    
    // MARK: - Mappers
    
    private func mapToDomainCart(_ serverCart: ServerCart) async throws -> Cart {
        var mergedItems: [String: CartItem] = [:]
        
        // Fetch full menu to resolve products
        let menu = try await productRepository.getMenu()
        let productsMap = Dictionary(uniqueKeysWithValues: menu.products.map { ($0.id, $0) })
        
        let storeId = serverCart.store_id ?? ""
        
        for item in serverCart.items {
            if let product = productsMap[item.product_id] {
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
                
                let cartItem = CartItem(
                    key: key,
                    product: product,
                    quantity: item.quantity,
                    customization: customization,
                    addedAt: Date(),
                    priceSnapshot: priceSnapshot,
                    storeId: storeId
                )
                
                mergedItems[key] = cartItem
            }
        }
        
        return Cart(
            items: Array(mergedItems.values),
            mode: .pickup,
            storeId: storeId.isEmpty ? nil : storeId,
            deliveryAddressId: nil,
            tableId: nil,
            voucherCode: nil,
            staffNotes: nil,
            lastUpdated: Date(),
            isDirty: false
        )
    }
}

// MARK: - Supporting Types (Private)

private struct CartServiceEmptyResponse: Codable {
    let success: Bool?
}

enum CartError: LocalizedError {
    case failedToFetch
    case failedToAdd
    case syncFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .failedToFetch: return "Failed to fetch cart"
        case .failedToAdd: return "Failed to add item to cart"
        case .syncFailed(let error): return "Cart sync failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - DTOs

struct GetCartPayload: Encodable {
    let store_id: String?
}

struct CartResponse {
    let success: Bool
    let cart: ServerCart?
    let error: String?
}

nonisolated extension CartResponse: Decodable {}

struct ServerCart {
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

nonisolated extension ServerCart: Decodable {}

struct ServerCartItem {
    let id: String
    let product_id: String
    let quantity: Int
    let modifiers: OrderCustomization?
    let price_snapshot: Double
}

nonisolated extension ServerCartItem: Decodable {}

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

