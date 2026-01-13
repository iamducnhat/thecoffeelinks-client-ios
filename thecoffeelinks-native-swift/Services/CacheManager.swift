import Foundation

final class CacheManager {
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let ioQueue = DispatchQueue(label: "com.appcafe.cache", attributes: .concurrent)
    
    private init() {
        // Use the caches directory
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = urls[0].appendingPathComponent("API_Cache")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Generic Caching
    
    func save<T: Encodable>(_ data: T, for key: String) async {
        await Task.detached(priority: .background) {
            let fileURL = self.cacheDirectory.appendingPathComponent(key + ".json")
            do {
                let encodedData = try JSONEncoder().encode(data)
                // Use barrier if we were using queue, but file system atomic write is usually ok.
                // To be safe against race with load, we can't easily sync across processes/tasks without queue.
                // But for this simple app, just writing atomic .atomicWrite is good enough.
                try encodedData.write(to: fileURL, options: .atomic)
            } catch {
                print("Cache save error for \(key): \(error)")
            }
        }.value
    }
    
    func load<T: Decodable>(_ type: T.Type, for key: String) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent(key + ".json")
        // Sync read
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decodedObject = try JSONDecoder().decode(type, from: data)
            return decodedObject
        } catch {
            print("Cache load error for \(key): \(error)")
            return nil
        }
    }
    
    func hasCachedData(for key: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent(key + ".json")
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
