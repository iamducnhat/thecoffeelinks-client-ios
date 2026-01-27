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

protocol SyncableDomain: AnyObject {
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
    func triggerSync(reason: SyncReason)
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
    private let lock = NSLock()
    
    // Monitors
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.thecoffeelinks.sync.network")
    private var isConnected = true
    private var cancellables = Set<AnyCancellable>()
    
    init(syncRepository: SyncRepositoryProtocol, userDefaults: UserDefaults = .standard) {
        self.syncRepository = syncRepository
        self.userDefaults = userDefaults
        
        setupMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupMonitoring() {
        // Network Monitor
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let connected = path.status == .satisfied
            if connected && !self.isConnected {
                // Reconnect detected
                Task { await self.triggerSync(reason: .networkReconnect) }
            }
            self.isConnected = connected
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
    
    // MARK: - Public API
    
    func register(domain: SyncableDomain) {
        lock.lock()
        defer { lock.unlock() }
        registeredDomains.append(WeakDomain(value: domain))
        // Trigger initial sync for this domain
        Task { await domain.sync(reason: .launch) }
    }
    
    func triggerSync(reason: SyncReason) {
        Task {
            // 1. Refresh Versions first (Global State)
            try? await refreshVersions()
            
            // 2. Notify all domains
            let domains = getValidDomains()
            
            await withTaskGroup(of: Void.self) { group in
                for domain in domains {
                    group.addTask {
                        await domain.sync(reason: reason)
                    }
                }
            }
        }
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
    
    // MARK: - Helpers
    
    private func getValidDomains() -> [SyncableDomain] {
        lock.lock()
        defer { lock.unlock() }
        // Cleanup and return
        registeredDomains.removeAll { $0.value == nil }
        return registeredDomains.compactMap { $0.value }
    }
}

// Helper for weak references
private struct WeakDomain {
    weak var value: SyncableDomain?
}


