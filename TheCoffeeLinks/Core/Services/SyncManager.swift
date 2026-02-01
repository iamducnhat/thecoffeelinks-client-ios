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
}

// MARK: - Implementation

final class SyncManager: SyncManagerProtocol, @unchecked Sendable {
    
    // Dependencies
    private let syncRepository: SyncRepositoryProtocol
    private let userDefaults: UserDefaults
    private let versionPrefix = "sync_version_"
    
    // State
    private var registeredDomains: [WeakDomain] = []
    private var versions: [String: Int] = [:]
    private let stateQueue = DispatchQueue(label: "com.thecoffeelinks.sync.state", attributes: .concurrent)
    private var _isConnected = true
    
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
    
    // Monitors
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.thecoffeelinks.sync.network")
    private var cancellables = Set<AnyCancellable>()
    
    init(syncRepository: SyncRepositoryProtocol, userDefaults: UserDefaults = .standard) {
        self.syncRepository = syncRepository
        self.userDefaults = userDefaults
        
        setupMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupMonitoring() {
        // Network Monitor - simplified to avoid Sendable closure issues
        monitor.pathUpdateHandler = { [weak self] _ in
            // Periodically trigger sync when network changes
            // Avoid accessing mutable state from Sendable closure
            self?.performPeriodicSyncAsync()
        }
        monitor.start(queue: monitorQueue)
        
        // App Lifecycle
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { await self?.triggerSync(reason: .foreground) }
            }
            .store(in: &cancellables)
            
        // Background Tick (Every 60s)
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                 Task { await self?.triggerSync(reason: .periodic) }
            }
            .store(in: &cancellables)
    }
    
    private nonisolated func performPeriodicSyncAsync() {
        // Wrap in Task to get to async context
        Task { [weak self] in
            await self?.triggerSync(reason: .networkReconnect)
        }
    }
    
    // MARK: - Public API
    
    func register(domain: SyncableDomain) {
        registeredDomains.append(WeakDomain(value: domain))
        // Trigger initial sync for this domain
        Task { await domain.sync(reason: .launch) }
    }
    
    func triggerSync(reason: SyncReason) async {
        // 1. Refresh Versions first (Global State)
        do {
            try await refreshVersions()
        } catch {
            print("⚠️ [SyncManager] Version refresh failed: \\(error), skipping selective sync")
            return
        }
        
        // 2. Notify only stale domains
        let domains = getValidDomains()
        
        await withTaskGroup(of: Void.self) { group in
            for domain in domains {
                // Check if domain is stale before syncing
                if let serverVersion = serverVersion(for: domain.domainKey) {
                    if isStale(key: domain.domainKey, serverVersion: serverVersion) {
                        group.addTask {
                            print("🔄 [SyncManager] Syncing stale domain: \\(domain.domainKey)")
                            await domain.sync(reason: reason)
                        }
                    } else {
                        print("✅ [SyncManager] Skipping fresh domain: \\(domain.domainKey)")
                    }
                } else {
                    // No version info, sync by default
                    group.addTask {
                        await domain.sync(reason: reason)
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
        let localVersion = userDefaults.integer(forKey: versionPrefix + key)
        return serverVersion > localVersion
    }
    
    func updateLocalVersion(key: String, version: Int) {
        userDefaults.set(version, forKey: versionPrefix + key)
    }
    
    // Helper to get current server version for a key (after refresh)
    func serverVersion(for key: String) -> Int? {
        stateQueue.sync {
            versions[key]
        }
    }
    
    // MARK: - Helpers
    
    private func getValidDomains() -> [SyncableDomain] {
        // Cleanup and return
        registeredDomains.removeAll { $0.value == nil }
        return registeredDomains.compactMap { $0.value }
    }
}

// Helper for weak references
private struct WeakDomain {
    weak var value: SyncableDomain?
}


