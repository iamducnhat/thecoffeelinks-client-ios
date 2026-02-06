//
//  CartStorage.swift
//  TheCoffeeLinks
//
//  Created for Local-First Architecture
//

import Foundation

protocol CartStorageProtocol {
    nonisolated func saveCart(_ cart: Cart) throws
    nonisolated func loadCart() -> Cart?
    nonisolated func clearCart()
}

final class CartStorage: CartStorageProtocol {
    private nonisolated(unsafe) let fileManager = FileManager.default
    private nonisolated let queue = DispatchQueue(label: "com.thecoffeelinks.cartstorage", qos: .userInitiated)
    
    // File location: Documents/cart_v1.json
    private nonisolated var cartFileURL: URL? {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documents.appendingPathComponent("cart_v1.json")
    }
    
    nonisolated func saveCart(_ cart: Cart) throws {
        guard let url = cartFileURL else { return }
        // Run on background queue to avoid main thread blocking (though small JSON is fast)
        // But for safety against race conditions, we use sync or handle async.
        // Prompt requirement: "Load immediately", so sync read is good. Write can be async but safer sync for consistency.
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(cart)
        try data.write(to: url, options: [.atomic])
    }
    
    nonisolated func loadCart() -> Cart? {
        guard let url = cartFileURL, fileManager.fileExists(atPath: url.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Cart.self, from: data)
        } catch {
            print("❌ Failed to load local cart: \(error)")
            return nil
        }
    }
    
    nonisolated func clearCart() {
        guard let url = cartFileURL else { return }
        try? fileManager.removeItem(at: url)
    }
}
