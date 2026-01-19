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
}

// MARK: - Cache Service Actor

actor CacheService: CacheServiceProtocol {
    private let memoryCache: SendableNSCache<NSString, MemoryEntry>
    private let fileManager = FileManager.default
    
    // Computed property is safe on actor
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("AppContentCache")
    }
    
    init() {
        self.memoryCache = SendableNSCache(countLimit: 50)
        // Creating directory is side-effect, assume safe on init or move to method
        // Actor init is synchronous, so we perform synchronous file op (safe for init)
        self.createCacheDirectory()
    }
    
    private func createCacheDirectory() {
        guard let url = cacheDirectory else { return }
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
        // Optimization: Capture the immutable URL *before* detaching.
        guard let cacheDir = self.cacheDirectory else { return nil }
        
        // T is Sendable, so DiskEntry<T> is Sendable, safe to return from Task.
        return await Task.detached(priority: .userInitiated) { [cacheDir] () -> (DiskEntry<T>, Bool)? in
            let fileURL = cacheDir.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
            let fileManager = FileManager.default
            
            guard fileManager.fileExists(atPath: fileURL.path),
                  let data = try? Data(contentsOf: fileURL),
                  let diskEntry = try? JSONDecoder().decode(DiskEntry<T>.self, from: data)
            else { return nil }
            
            let isExpired: Bool
            if let ttl = diskEntry.ttl {
                 isExpired = Date() > diskEntry.createdAt.addingTimeInterval(ttl)
            } else {
                isExpired = false
            }
            
            return (diskEntry, isExpired)
        }.value.flatMap { (diskEntry: DiskEntry<T>, isExpired: Bool) in
            // Back on Actor: Populate L1
            // value is known Sendable now
            let memEntry = MemoryEntry(value: diskEntry.value, ttl: diskEntry.ttl, createdAt: diskEntry.createdAt)
            self.memoryCache.setObject(memEntry, forKey: key as NSString)
            
            return (diskEntry.value, isExpired)
        }
    }
    
    func set<T: Codable & Sendable>(_ key: String, value: T, ttl: TimeInterval?) async {
        let now = Date()
        
        // 1. Write to L1 Memory
        // Value is guaranteed Sendable by T constraint
        let memEntry = MemoryEntry(value: value, ttl: ttl, createdAt: now)
        memoryCache.setObject(memEntry, forKey: key as NSString)
        
        // 2. Write to L2 Disk
        guard let cacheDir = self.cacheDirectory else { return }
        
        Task.detached(priority: .background) { [cacheDir] in
            let fileURL = cacheDir.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
            let diskEntry = DiskEntry(value: value, ttl: ttl, createdAt: now)
            if let data = try? JSONEncoder().encode(diskEntry) {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }
    
    func remove(_ key: String) async {
        memoryCache.removeObject(forKey: key as NSString)
        
        guard let cacheDir = self.cacheDirectory else { return }
        
        Task.detached(priority: .background) { [cacheDir] in
            let fileURL = cacheDir.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    func clear() async {
        memoryCache.removeAllObjects()
        
        guard let cacheDir = self.cacheDirectory else { return }
        
        Task.detached(priority: .background) { [cacheDir] in
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: cacheDir)
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
    }
}
