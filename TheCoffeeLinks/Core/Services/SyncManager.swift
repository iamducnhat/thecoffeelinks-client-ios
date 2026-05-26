//
//  SyncManager.swift
//  TheCoffeeLinks
//
//  Created for Local-First Architecture
//

import Foundation
import Network
import Combine
import UIKit

// MARK: - Protocols

protocol SyncableDomain: AnyObject, Sendable {
    var domainKey: String { get }
    func sync(reason: SyncReason) async
}

enum SyncReason: String {
    case launch
    case foreground
    case networkReconnect
    case periodic
    case manual
}

protocol SyncManagerProtocol: Sendable {
    func register(domain: SyncableDomain)
    func triggerSync(reason: SyncReason) async
    func refreshVersions() async throws
    func isStale(key: String, serverVersion: Int) -> Bool
    func updateLocalVersion(key: String, version: Int)
    func serverVersion(for key: String) -> Int?
}

// MARK: - Implementation

final class SyncManager: SyncManagerProtocol, @unchecked Sendable {
    
    // Dependencies
    private let syncRepository: SyncRepositoryProtocol
    private let userDefaults: UserDefaults
    private let versionPrefix = "sync_version_"
    
    // State
    private nonisolated(unsafe) var registeredDomains: [WeakDomain] = []
    private nonisolated(unsafe) var versions: [String: Int] = [:]
    private let stateQueue = DispatchQueue(label: "com.thecoffeelinks.sync.state", attributes: .concurrent)
    private let minimumSyncInterval: TimeInterval = 600
    private nonisolated(unsafe) var _isConnected = true
    private nonisolated(unsafe) var _lastSyncAt: Date?
    
    private var isConnected: Bool {
        get {
            stateQueue.sync {
                _isConnected
            }
        }
        set {
            stateQueue.async(flags: .barrier) {
                self._isConnected = newValue
            }
        }
    }

    private nonisolated func updateConnectionState(_ connected: Bool) -> Bool {
        var wasConnected = true
        stateQueue.sync(flags: .barrier) {
            wasConnected = _isConnected
            _isConnected = connected
        }
        return wasConnected
    }
    
    // Monitors
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.thecoffeelinks.sync.network")
    private var cancellables = Set<AnyCancellable>()
    
    private let keychainManager: KeychainManager?
    
    init(syncRepository: SyncRepositoryProtocol, userDefaults: UserDefaults = .standard, keychainManager: KeychainManager? = nil) {
        self.syncRepository = syncRepository
        self.userDefaults = userDefaults
        self.keychainManager = keychainManager
        
        setupMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupMonitoring() {
        // Network Monitor - sync only when connectivity is restored.
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            let wasConnected = self.updateConnectionState(connected)

            if connected && !wasConnected {
                self.performNetworkReconnectSyncAsync()
            }
        }
        monitor.start(queue: monitorQueue)
        
        // App Lifecycle
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { await self?.triggerSync(reason: .foreground) }
            }
            .store(in: &cancellables)
    }
    
    private nonisolated func performNetworkReconnectSyncAsync() {
        // Wrap in Task to get to async context
        Task { [weak self] in
            await self?.triggerSync(reason: .networkReconnect)
        }
    }
    
    // MARK: - Public API
    
    func register(domain: SyncableDomain) {
        stateQueue.sync(flags: .barrier) {
            self.registeredDomains.append(WeakDomain(value: domain))
        }
        // Trigger initial sync for this domain
        Task { [weak self] in
            await self?.triggerSync(reason: .launch)
        }
    }
    
    func triggerSync(reason: SyncReason) async {
        // Skip sync in guest mode — no point hitting the server without a token
        if let km = keychainManager, km.getAccessToken() == nil {
            debugLog("⏭️ [SyncManager] Skipping \(reason.rawValue) sync — not authenticated")
            return
        }

        guard shouldRunSync(reason: reason) else {
            debugLog("⏭️ [SyncManager] Throttled \(reason.rawValue) sync")
            return
        }
        
        // 1. Refresh Versions first (Global State)
        do {
            try await refreshVersions()
        } catch {
            debugLog("⚠️ [SyncManager] Version refresh failed: \(error), skipping selective sync")
            return
        }
        
        // 2. Notify only stale domains
        let domains = getValidDomains()
        
        await withTaskGroup(of: Void.self) { group in
            for domain in domains {
                let domainKey = domain.domainKey
                // Check if domain is stale before syncing
                if let serverVersion = serverVersion(for: domainKey) {
                    if isStale(key: domainKey, serverVersion: serverVersion) {
                        group.addTask {
                            debugLog("🔄 [SyncManager] Syncing stale domain: \(domainKey)")
                            await domain.sync(reason: reason)
                        }
                    } else {
                        debugLog("✅ [SyncManager] Skipping fresh domain: \(domainKey)")
                    }
                } else {
                    // Unknown domains are intentionally conservative: launch/manual only.
                    if reason == .launch || reason == .manual {
                        group.addTask {
                            await domain.sync(reason: reason)
                        }
                    } else {
                        debugLog("⏭️ [SyncManager] Skipping unversioned domain: \(domainKey)")
                    }
                }
            }
        }
    }
    
    func refreshVersions() async throws {
        let fetchedVersions = try await syncRepository.getVersions()
        stateQueue.async(flags: .barrier) {
            self.versions = fetchedVersions
        }
    }
    
    func isStale(key: String, serverVersion: Int) -> Bool {
        let localVersion = versionKeyCandidates(for: key)
            .map { userDefaults.integer(forKey: versionPrefix + $0) }
            .max() ?? 0
        return serverVersion > localVersion
    }
    
    func updateLocalVersion(key: String, version: Int) {
        for candidate in versionKeyCandidates(for: key) {
            userDefaults.set(version, forKey: versionPrefix + candidate)
        }
    }
    
    // Helper to get current server version for a key (after refresh)
    func serverVersion(for key: String) -> Int? {
        stateQueue.sync {
            for candidate in versionKeyCandidates(for: key) {
                if let version = versions[candidate] {
                    return version
                }
            }
            return nil
        }
    }
    
    // MARK: - Helpers

    private func shouldRunSync(reason: SyncReason) -> Bool {
        if reason == .manual {
            stateQueue.async(flags: .barrier) {
                self._lastSyncAt = Date()
            }
            return true
        }

        var shouldRun = false
        stateQueue.sync(flags: .barrier) {
            let now = Date()
            if let lastSyncAt = _lastSyncAt, now.timeIntervalSince(lastSyncAt) < minimumSyncInterval {
                shouldRun = false
            } else {
                _lastSyncAt = now
                shouldRun = true
            }
        }
        return shouldRun
    }

    private func versionKeyCandidates(for key: String) -> [String] {
        switch key {
        case "store_status":
            return ["store_status", "stores"]
        case "user_vouchers":
            return ["user_vouchers", "vouchers"]
        case let menuKey where menuKey.hasPrefix("menu:"):
            return [menuKey, "menu"]
        default:
            return [key]
        }
    }
    
    private func getValidDomains() -> [SyncableDomain] {
        // Cleanup and return
        stateQueue.sync(flags: .barrier) {
            registeredDomains.removeAll { $0.value == nil }
            return registeredDomains.compactMap { $0.value }
        }
    }
}

// Helper for weak references
private struct WeakDomain {
    weak var value: SyncableDomain?
}
