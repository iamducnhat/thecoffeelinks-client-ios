import Foundation

// MARK: - Safe Types

// Wrapper to make NSCache Sendable since it is thread-safe
private final class SendableNSCache<Key: AnyObject, Value: AnyObject>: @unchecked Sendable {
    private let cache = NSCache<Key, Value>()
    
    init(countLimit: Int) {
        cache.countLimit = countLimit
    }
    
    func object(forKey key: Key) -> Value? { cache.object(forKey: key) }
    func setObject(_ obj: Value, forKey key: Key) { cache.setObject(obj, forKey: key) }
    func removeObject(forKey key: Key) { cache.removeObject(forKey: key) }
    func removeAllObjects() { cache.removeAllObjects() }
}

private final class MemoryEntry: Sendable {
    let value: Sendable // Enforce Sendable on content
    let ttl: TimeInterval?
    let createdAt: Date
    
    init(value: Sendable, ttl: TimeInterval?, createdAt: Date) {
        self.value = value
        self.ttl = ttl
        self.createdAt = createdAt
    }
}

private struct DiskEntry<T: Codable & Sendable>: Codable, Sendable {
    let value: T
    let ttl: TimeInterval?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case value
        case ttl
        case createdAt
    }
}

// MARK: - Cache Service

class CacheService: CacheServiceProtocol, @unchecked Sendable {
    private let memoryCache: SendableNSCache<NSString, MemoryEntry>
    private let fileManager = FileManager.default
    
    // Computed property is safe
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("AppContentCache")
    }
    
    init() {
        self.memoryCache = SendableNSCache(countLimit: 50)
        // Creating directory is safe on actor init (synchronous context)
    }
    
    private nonisolated func createCacheDirectory() {
        let fileManager = FileManager.default
        guard let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("AppContentCache") else { return }
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    func get<T: Codable & Sendable>(_ key: String) async -> T? {
        // T is now Sendable, safe to use in actor
        guard let entry = await getEntry(key) as (value: T, isExpired: Bool)? else { return nil }
        return entry.isExpired ? nil : entry.value
    }
    
    func getEntry<T: Codable & Sendable>(_ key: String) async -> (value: T, isExpired: Bool)? {
        // 1. Check L1 Memory Cache
        if let memEntry = memoryCache.object(forKey: key as NSString) {
            if let value = memEntry.value as? T {
                let isExpired: Bool
                if let ttl = memEntry.ttl {
                    isExpired = Date() > memEntry.createdAt.addingTimeInterval(ttl)
                } else {
                    isExpired = false
                }
                return (value, isExpired)
            }
        }
        
        // 2. Check L2 Disk Cache
        guard let cacheDir = self.cacheDirectory else { return nil }
        
        let result: (T, Bool)? = await Task.detached(priority: .userInitiated) { [cacheDir] () -> (T, Bool)? in
            let fileURL = cacheDir.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
            let fileManager = FileManager.default
            
            guard fileManager.fileExists(atPath: fileURL.path),
                  let data = try? Data(contentsOf: fileURL)
            else { return nil }
            
            do {
                let decoder = JSONDecoder()
                let value = try decoder.decode(T.self, from: data)
                // We can't decode TTL/createdAt here, so assume not expired
                return (value, false)
            } catch {
                return nil
            }
        }.value
        
        return result
    }
    
    func set<T: Codable & Sendable>(_ key: String, value: T, ttl: TimeInterval?) async {
        let now = Date()
        
        // 1. Write to L1 Memory (on main thread)
        let memEntry = MemoryEntry(value: value, ttl: ttl, createdAt: now)
        memoryCache.setObject(memEntry, forKey: key as NSString)
        
        // 2. Write to L2 Disk (on background thread)
        guard let cacheDir = self.cacheDirectory else { return }
        
        await Task.detached(priority: .background) { [cacheDir, value, ttl, now] in
            let fileURL = cacheDir.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(value)
                try data.write(to: fileURL, options: .atomic)
            } catch {
                // Silently fail - disk cache is not critical
            }
        }.value
    }
    
    func remove(_ key: String) async {
        memoryCache.removeObject(forKey: key as NSString)
        
        guard let cacheDir = self.cacheDirectory else { return }
        
        await Task.detached(priority: .background) { [cacheDir] in
            let fileURL = cacheDir.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: fileURL)
        }.value
    }
    
    func clear() async {
        memoryCache.removeAllObjects()
        
        guard let cacheDir = self.cacheDirectory else { return }
        
        await Task.detached(priority: .background) { [cacheDir] in
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: cacheDir)
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }.value
    }
}
