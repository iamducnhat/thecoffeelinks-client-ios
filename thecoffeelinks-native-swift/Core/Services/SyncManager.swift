import Foundation

protocol SyncManagerProtocol: Sendable {
    func refreshVersions() async throws
    func isStale(key: String, serverVersion: Int) -> Bool
    func updateLocalVersion(key: String, version: Int)
}

final class SyncManager: SyncManagerProtocol, @unchecked Sendable {
    private let syncRepository: SyncRepositoryProtocol
    private let userDefaults: UserDefaults
    private let versionPrefix = "sync_version_"
    
    private var versions: [String: Int] = [:]
    private let lock = NSLock()
    
    init(syncRepository: SyncRepositoryProtocol, userDefaults: UserDefaults = .standard) {
        self.syncRepository = syncRepository
        self.userDefaults = userDefaults
    }
    
    func refreshVersions() async throws {
        let fetchedVersions = try await syncRepository.getVersions()
        lock.lock()
        self.versions = fetchedVersions
        lock.unlock()
    }
    
    func isStale(key: String, serverVersion: Int) -> Bool {
        let localVersion = userDefaults.integer(forKey: versionPrefix + key)
        return serverVersion > localVersion
    }
    
    func updateLocalVersion(key: String, version: Int) {
        userDefaults.set(version, forKey: versionPrefix + key)
    }
    
    // Helper to get current server version for a key (after refresh)
    func serverVersion(for key: String) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        return versions[key]
    }
}
