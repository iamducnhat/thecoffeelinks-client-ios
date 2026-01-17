import Foundation

final class CacheService: CacheServiceProtocol, @unchecked Sendable {
    private let cache = NSCache<NSString, CacheEntry>()
    
    init() {
        cache.countLimit = 100
    }
    
    func get<T: Codable>(_ key: String) async -> T? {
        guard let entry = cache.object(forKey: key as NSString) else { return nil }
        
        if let ttl = entry.ttl, Date() > entry.expiryDate(ttl: ttl) {
             cache.removeObject(forKey: key as NSString)
             return nil
        }
        
        return entry.value as? T
    }
    
    func set<T: Codable>(_ key: String, value: T, ttl: TimeInterval?) async {
        let entry = CacheEntry(value: value, ttl: ttl, createdAt: Date())
        cache.setObject(entry, forKey: key as NSString)
    }
    
    func remove(_ key: String) async {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clear() async {
        cache.removeAllObjects()
    }
}

private class CacheEntry: NSObject {
    let value: Any
    let ttl: TimeInterval?
    let createdAt: Date
    
    init(value: Any, ttl: TimeInterval?, createdAt: Date) {
        self.value = value
        self.ttl = ttl
        self.createdAt = createdAt
    }
    
    func expiryDate(ttl: TimeInterval) -> Date {
        createdAt.addingTimeInterval(ttl)
    }
}
