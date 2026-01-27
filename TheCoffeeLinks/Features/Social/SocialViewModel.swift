//
//  SocialViewModel.swift
//  thecoffeelinks-client-ios
//
//  Presence, connections, block/report with privacy-first defaults
//

import Foundation
import Combine

@MainActor
final class SocialViewModel: ObservableObject {
    @Published var presences: [StorePresence] = []
    @Published var connections: [Connection] = []
    @Published var myPresence: StorePresence?
    @Published var currentMode: ConnectionMode = .focus
    @Published var currentStatus: PresenceStatus = .available
    @Published var nearbyUsers: [StorePresence] = []
    @Published var isCheckedIn = false
    @Published var currentStoreId: String?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var blockedUsers: Set<String> = []
    
    private let socialRepository: SocialRepositoryProtocol
    private let presenceService: PresenceServiceProtocol
    private let userRepository: UserRepositoryProtocol
    private nonisolated(unsafe) var refreshTimer: Timer?
    
    init(socialRepository: SocialRepositoryProtocol, presenceService: PresenceServiceProtocol, userRepository: UserRepositoryProtocol) {
        self.socialRepository = socialRepository
        self.presenceService = presenceService
        self.userRepository = userRepository
    }
    
    nonisolated(unsafe) func getRefreshTimer() -> Timer? {
        refreshTimer
    }
    
    deinit {
        // Timer invalidation in deinit to prevent memory leaks
        getRefreshTimer()?.invalidate()
    }
    
    var visiblePresences: [StorePresence] {
        presences.filter { presence in
            guard !blockedUsers.contains(presence.userId) else { return false }
            // In open mode, all open users are visible
            // In focus mode, no one is visible
            return currentMode == .open && presence.mode == .open
        }
    }
    
    var availableCount: Int { visiblePresences.filter { $0.status == .available }.count }
    var focusedCount: Int { visiblePresences.filter { $0.status == .focused }.count }
    
    func loadConnections() async {
        do { connections = try await socialRepository.getConnections() }
        catch { self.error = error }
    }
    
    func loadPresences() async {
        do {
            nearbyUsers = try await socialRepository.getPresences(storeId: currentStoreId ?? "")
        } catch {
            self.error = error
        }
    }
    
    func loadPresences(storeId: String) async {
        currentStoreId = storeId
        do { presences = try await socialRepository.getPresences(storeId: storeId) }
        catch { self.error = error }
    }
    
    func checkIn(storeId: String, mode: ConnectionMode? = nil) async {
        isLoading = true
        if let mode = mode {
            currentMode = mode
        }
        do {
            try await presenceService.connect(storeId: storeId)
            myPresence = try await socialRepository.checkIn(storeId: storeId, status: currentStatus)
            isCheckedIn = true; currentStoreId = storeId
            await loadPresences(storeId: storeId)
            startAutoRefresh()
        } catch { self.error = error }
        isLoading = false
    }
    
    func checkOut() async {
        guard isCheckedIn, let storeId = currentStoreId else { return }
        do {
            try await presenceService.checkOut()
            try await socialRepository.checkOut(storeId: storeId)
            isCheckedIn = false; myPresence = nil; presences = []
            stopAutoRefresh()
            await presenceService.disconnect()
        } catch { self.error = error }
    }
    
    func updateStatus(_ status: PresenceStatus) async {
        currentStatus = status
        guard isCheckedIn else { return }
        do { try await presenceService.updateStatus(status); try await socialRepository.updateStatus(status) }
        catch { self.error = error }
    }
    
    func updateMode(_ mode: ConnectionMode) async {
        currentMode = mode
        guard isCheckedIn else { return }
        do { try await socialRepository.updateMode(mode) }
        catch { self.error = error }
    }
    
    private func startAutoRefresh() {
        stopAutoRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let storeId = self.currentStoreId else { return }
                await self.loadPresences(storeId: storeId)
            }
        }
    }
    
    private func stopAutoRefresh() { refreshTimer?.invalidate(); refreshTimer = nil }
    
    func sendConnectionRequest(to userId: String, message: String?) async -> ConnectionRequest? {
        do { return try await socialRepository.sendConnectionRequest(toUserId: userId, message: message) }
        catch { self.error = error; return nil }
    }
    
    func respondToRequest(_ requestId: String, accept: Bool) async {
        do { try await socialRepository.respondToRequest(id: requestId, accept: accept); if accept { await loadConnections() } }
        catch { self.error = error }
    }
    
    func blockUser(_ userId: String, reason: String? = nil) async {
        do {
            let _ = try await socialRepository.blockUser(userId: userId, reason: reason)
            blockedUsers.insert(userId)
            connections.removeAll { $0.friendId == userId }
            presences.removeAll { $0.userId == userId }
        } catch { self.error = error }
    }
    
    func unblockUser(_ userId: String) async {
        do { try await socialRepository.unblockUser(userId: userId); blockedUsers.remove(userId) }
        catch { self.error = error }
    }
    
    func reportUser(_ userId: String, reason: ReportReason, details: String?) async {
        do { let _ = try await socialRepository.reportUser(userId: userId, reason: reason, details: details); await blockUser(userId) }
        catch { self.error = error }
    }
    
    func sendTreat(to userId: String, amount: Double, message: String?) async -> CoffeeTreat? {
        do { return try await socialRepository.sendTreat(toUserId: userId, amount: amount, message: message) }
        catch { self.error = error; return nil }
    }
}
