//
//  GenericStorage.swift
//  TheCoffeeLinks
//
//  Created for Local-First Architecture
//

import Foundation

protocol GenericStorageProtocol {
    func save<T: Encodable>(_ object: T, key: String) throws
    func load<T: Decodable>(_ type: T.Type, key: String) -> T?
    func remove(key: String)
}

final class GenericStorage: GenericStorageProtocol {
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.thecoffeelinks.storage", qos: .userInitiated, attributes: .concurrent)
    
    private func fileURL(for key: String) -> URL? {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documents.appendingPathComponent("\(key).json")
    }
    
    func save<T: Encodable>(_ object: T, key: String) throws {
        guard let url = fileURL(for: key) else { return }
        
        // Synchronous write for consistency as requested ("immediate persistence")
        // But wrapped in a barrier to prevent race conditions if called from multiple threads
        try queue.sync(flags: .barrier) {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(object)
            try data.write(to: url, options: [.atomic])
        }
    }
    
    func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let url = fileURL(for: key) else { return nil }
        
        return queue.sync {
            guard fileManager.fileExists(atPath: url.path) else { return nil }
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                debugLog("❌ Failed to load local \(key): \(error)")
                return nil
            }
        }
    }
    
    func remove(key: String) {
        guard let url = fileURL(for: key) else { return }
        
        queue.sync(flags: .barrier) {
            try? fileManager.removeItem(at: url)
        }
    }
}
