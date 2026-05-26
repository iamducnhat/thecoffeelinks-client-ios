import Foundation

// MARK: - Safe Types

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

// MARK: - Cache Service

class CacheService: CacheServiceProtocol, @unchecked Sendable {
    private let memoryCache: NSCache<NSString, MemoryEntry>
    private let fileManager = FileManager.default
    private let maxDiskEntries = 100
    private let maxDiskBytes: Int64 = 20 * 1024 * 1024
    
    // Computed property is safe
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("AppContentCache")
    }
    
    init() {
        let memoryCache = NSCache<NSString, MemoryEntry>()
        memoryCache.countLimit = 50
        self.memoryCache = memoryCache
        createCacheDirectory()
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
                if let object = try? JSONSerialization.jsonObject(with: data),
                   let envelope = object as? [String: Any],
                   let payload = envelope["payload"] as? String,
                   let payloadData = Data(base64Encoded: payload),
                   let createdAtSeconds = Self.doubleValue(from: envelope["createdAt"]) {
                    let ttl = Self.doubleValue(from: envelope["ttl"])
                    let createdAt = Date(timeIntervalSince1970: createdAtSeconds)
                    let isExpired = ttl.map { Date() > createdAt.addingTimeInterval($0) } ?? false
                    if isExpired {
                        try? fileManager.removeItem(at: fileURL)
                    }
                    let value = try decoder.decode(T.self, from: payloadData)
                    return (value, isExpired)
                }

                // Backward compatibility for older raw-value disk cache files.
                let value = try decoder.decode(T.self, from: data)
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
        
        await Task.detached(priority: .background) { [cacheDir, value, ttl, now, maxDiskEntries, maxDiskBytes] in
            let fileURL = cacheDir.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
            do {
                let encoder = JSONEncoder()
                let payloadData = try encoder.encode(value)
                var envelope: [String: Any] = [
                    "payload": payloadData.base64EncodedString(),
                    "createdAt": now.timeIntervalSince1970,
                ]
                if let ttl {
                    envelope["ttl"] = ttl
                }
                let data = try JSONSerialization.data(withJSONObject: envelope)
                try data.write(to: fileURL, options: .atomic)
                Self.enforceDiskLimits(cacheDir: cacheDir, fileManager: FileManager.default, maxEntries: maxDiskEntries, maxBytes: maxDiskBytes)
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

    private nonisolated static func enforceDiskLimits(cacheDir: URL, fileManager: FileManager, maxEntries: Int, maxBytes: Int64) {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: cacheDir,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var files: [(url: URL, modified: Date, size: Int64)] = []
        var totalBytes: Int64 = 0

        for url in urls {
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]) else { continue }
            let size = Int64(values.fileSize ?? 0)
            totalBytes += size
            files.append((url, values.contentModificationDate ?? .distantPast, size))
        }

        guard files.count > maxEntries || totalBytes > maxBytes else { return }

        for file in files.sorted(by: { $0.modified < $1.modified }) where files.count > maxEntries || totalBytes > maxBytes {
            try? fileManager.removeItem(at: file.url)
            totalBytes -= file.size
            files.removeAll { $0.url == file.url }
        }
    }

    private nonisolated static func doubleValue(from value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? NSNumber { return value.doubleValue }
        return nil
    }
}
