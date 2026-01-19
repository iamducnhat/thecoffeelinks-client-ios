import Foundation

final class CacheService: CacheServiceProtocol, @unchecked Sendable {
    private let memoryCache = NSCache<NSString, MemoryEntry>()
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.thecoffeelinks.cache.disk", attributes: .concurrent)
    
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("AppContentCache")
    }
    
    init() {
        memoryCache.countLimit = 50
        createCacheDirectory()
    }
    
    private func createCacheDirectory() {
        guard let url = cacheDirectory else { return }
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    func get<T: Codable>(_ key: String) async -> T? {
        guard let entry = await getEntry(key) as (value: T, isExpired: Bool)? else { return nil }
        return entry.isExpired ? nil : entry.value
    }
    
    func getEntry<T: Codable>(_ key: String) async -> (value: T, isExpired: Bool)? {
        // 1. Check L1 Memory Cache
        if let memEntry = memoryCache.object(forKey: key as NSString) {
            // Validate type safely
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
        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self, let cacheDir = self.cacheDirectory else { return nil }
            let fileURL = cacheDir.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
            
            guard self.fileManager.fileExists(atPath: fileURL.path),
                  let data = try? Data(contentsOf: fileURL),
                  let diskEntry = try? JSONDecoder().decode(DiskEntry<T>.self, from: data)
            else { return nil }
            
            // Populate L1
            let memEntry = MemoryEntry(value: diskEntry.value, ttl: diskEntry.ttl, createdAt: diskEntry.createdAt)
            self.memoryCache.setObject(memEntry, forKey: key as NSString)
            
            let isExpired: Bool
            if let ttl = diskEntry.ttl {
                 isExpired = Date() > diskEntry.createdAt.addingTimeInterval(ttl)
            } else {
                isExpired = false
            }
            
            return (diskEntry.value, isExpired)
        }.value
    }
    
    func set<T: Codable>(_ key: String, value: T, ttl: TimeInterval?) async {
        let now = Date()
        
        // 1. Write to L1 Memory
        let memEntry = MemoryEntry(value: value, ttl: ttl, createdAt: now)
        memoryCache.setObject(memEntry, forKey: key as NSString)
        
        // 2. Write to L2 Disk
        Task.detached(priority: .background) { [weak self] in
            guard let self = self, let cacheDir = self.cacheDirectory else { return }
            let fileURL = cacheDir.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
            
            let diskEntry = DiskEntry(value: value, ttl: ttl, createdAt: now)
            if let data = try? JSONEncoder().encode(diskEntry) {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }
    
    func remove(_ key: String) async {
        memoryCache.removeObject(forKey: key as NSString)
        
        Task.detached(priority: .background) { [weak self] in
            guard let self = self, let cacheDir = self.cacheDirectory else { return }
            let fileURL = cacheDir.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
            try? self.fileManager.removeItem(at: fileURL)
        }
    }
    
    func clear() async {
        memoryCache.removeAllObjects()
        
        Task.detached(priority: .background) { [weak self] in
            guard let self = self, let cacheDir = self.cacheDirectory else { return }
            try? self.fileManager.removeItem(at: cacheDir)
            self.createCacheDirectory()
        }
    }
}

// MARK: - Internal Models

private class MemoryEntry: NSObject {
    let value: Any
    let ttl: TimeInterval?
    let createdAt: Date
    
    init(value: Any, ttl: TimeInterval?, createdAt: Date) {
        self.value = value
        self.ttl = ttl
        self.createdAt = createdAt
    }
}

private struct DiskEntry<T: Codable>: Codable {
    let value: T
    let ttl: TimeInterval?
    let createdAt: Date
}
