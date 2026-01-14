//
//  ConnectViewModel.swift
//  thecoffeelinks-native-swift
//
//  ViewModel for Connect/Networking feature - handles all state and logic
//

import Foundation
import Combine
import SwiftUI

@MainActor
class ConnectViewModel: ObservableObject {
    // MARK: - Published State
    
    // View State
    @Published var viewState: ViewState = .idle
    @Published var isRefreshing = false
    
    // Check-In State
    @Published var currentCheckIn: EnhancedCheckIn?
    @Published var presenceStatus: PresenceStatus = .focusMode // Default to Focus Mode per requirements
    
    // Discovery
    @Published var discoverableUsers: [EnhancedCheckIn] = []
    @Published private(set) var isLoadingUsers = false
    
    // Connections
    @Published var pendingRequests: [ConnectionRequest] = []
    @Published var connections: [ConnectionRequest] = []
    @Published var connectionStatuses: [String: ConnectionStatus] = [:] // userId -> status
    
    // Coffee Treats
    @Published var pendingTreats: [CoffeeTreat] = []
    @Published var sentTreats: [CoffeeTreat] = []
    
    // Rate Limiting
    @Published var rateLimitInfo: RateLimitInfo?
    @Published var handshakeRequestsThisHour: Int = 0
    private let maxHandshakesPerHour = 10
    
    // Blocked Users (local cache for filtering)
    @Published var blockedUserIds: Set<String> = []
    
    // Error Handling
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Undo Support
    @Published var undoAction: UndoableAction?
    
    // MARK: - Dependencies
    
    private let connectService = ConnectService.shared
    private let storeService = StoreService()
    private var cancellables = Set<AnyCancellable>()
    
    // Rate limit tracking
    private var hourlyRequestTimestamps: [Date] = []
    
    // MARK: - Computed Properties
    
    var isCheckedIn: Bool {
        currentCheckIn != nil
    }
    
    var isDiscoverable: Bool {
        isCheckedIn && presenceStatus == .openToNetwork
    }
    
    var canSendHandshake: Bool {
        !isRateLimited
    }
    
    var isRateLimited: Bool {
        cleanOldRequests()
        return handshakeRequestsThisHour >= maxHandshakesPerHour
    }
    
    var requestsRemaining: Int {
        cleanOldRequests()
        return max(0, maxHandshakesPerHour - handshakeRequestsThisHour)
    }
    
    // Filter out blocked users from discovery
    var filteredDiscoverableUsers: [EnhancedCheckIn] {
        discoverableUsers.filter { checkIn in
            !blockedUserIds.contains(checkIn.userId)
        }
    }
    
    // MARK: - Initialization
    
    init() {
        loadPersistedState()
        setupRateLimitReset()
    }
    
    // MARK: - Check-In / Check-Out
    
    func checkIn(storeId: String?) async {
        viewState = .loading
        
        do {
            var finalStoreId = storeId
            
            // If no store specified, get nearest/first store
            if finalStoreId == nil {
                let stores = try await storeService.getStores()
                finalStoreId = stores.first?.id
            }
            
            guard let storeId = finalStoreId else {
                throw ConnectError.serverError("No store available for check-in")
            }
            
            // Check in with current presence status
            let checkIn = try await connectService.checkIn(storeId: storeId, status: presenceStatus)
            currentCheckIn = checkIn
            
            // Fetch discoverable users if open to network
            if presenceStatus == .openToNetwork {
                await fetchDiscoverableUsers()
            }
            
            // Fetch pending requests
            await fetchPendingRequests()
            await fetchPendingTreats()
            
            viewState = .loaded
            persistState()
            
        } catch {
            handleError(error)
        }
    }
    
    func checkOut() async {
        guard isCheckedIn else { return }
        
        do {
            try await connectService.checkOut()
            currentCheckIn = nil
            discoverableUsers = []
            persistState()
            viewState = .loaded
        } catch {
            handleError(error)
        }
    }
    
    func updatePresenceStatus(_ newStatus: PresenceStatus) async {
        let oldStatus = presenceStatus
        presenceStatus = newStatus
        
        // If checked in, update server
        if isCheckedIn {
            do {
                try await connectService.updatePresenceStatus(newStatus)
                
                // If switching to open, fetch discoverable users
                if newStatus == .openToNetwork {
                    await fetchDiscoverableUsers()
                } else {
                    // Clear discoverable users when going to focus mode
                    discoverableUsers = []
                }
                
                persistState()
                
            } catch {
                // Rollback on error
                presenceStatus = oldStatus
                handleError(error)
            }
        }
    }
    
    // MARK: - Discovery
    
    func fetchDiscoverableUsers() async {
        guard let storeId = currentCheckIn?.storeId else { return }
        guard presenceStatus == .openToNetwork else {
            discoverableUsers = []
            return
        }
        
        isLoadingUsers = true
        
        do {
            // Max 20 users per requirement
            let users = try await connectService.getDiscoverableUsers(storeId: storeId, limit: 20)
            
            // Filter blocked users
            discoverableUsers = users.filter { !blockedUserIds.contains($0.userId) }
            
            // Batch fetch connection statuses
            for user in discoverableUsers {
                if connectionStatuses[user.userId] == nil {
                    Task {
                        if let status = try? await connectService.getConnectionStatus(userId: user.userId) {
                            connectionStatuses[user.userId] = status
                        }
                    }
                }
            }
            
        } catch {
            // Silent fail for discovery - just show empty
            print("Discovery fetch failed: \(error)")
        }
        
        isLoadingUsers = false
    }
    
    func refresh() async {
        isRefreshing = true
        
        if isCheckedIn {
            await fetchDiscoverableUsers()
            await fetchPendingRequests()
            await fetchPendingTreats()
        }
        
        isRefreshing = false
    }
    
    // MARK: - Connections (Digital Handshake)
    
    func sendConnectionRequest(to userId: String, message: String? = nil) async -> Bool {
        // Rate limit check
        guard canSendHandshake else {
            showError = true
            errorMessage = "You've reached the limit of \(maxHandshakesPerHour) connection requests per hour."
            return false
        }
        
        // Block check
        guard !blockedUserIds.contains(userId) else {
            showError = true
            errorMessage = "Cannot connect with blocked user"
            return false
        }
        
        do {
            let request = try await connectService.sendConnectionRequest(toUserId: userId, message: message)
            connectionStatuses[userId] = .pending
            recordHandshakeRequest()
            
            // Add undo capability
            undoAction = UndoableAction(
                description: "Connection request sent",
                undoHandler: { [weak self] in
                    Task {
                        try? await self?.connectService.respondToConnection(requestId: request.id, accept: false)
                        self?.connectionStatuses[userId] = .none
                    }
                }
            )
            
            // Auto-dismiss undo after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if self?.undoAction?.description == "Connection request sent" {
                    self?.undoAction = nil
                }
            }
            
            return true
            
        } catch let error as ConnectError {
            if case .rateLimited = error {
                rateLimitInfo = RateLimitInfo(
                    requestsRemaining: 0,
                    resetTime: Date().addingTimeInterval(3600),
                    maxRequests: maxHandshakesPerHour
                )
            }
            handleError(error)
            return false
        } catch {
            handleError(error)
            return false
        }
    }
    
    func respondToRequest(_ requestId: String, accept: Bool, userId: String) async {
        do {
            try await connectService.respondToConnection(requestId: requestId, accept: accept)
            
            // Update local state
            pendingRequests.removeAll { $0.id == requestId }
            connectionStatuses[userId] = accept ? .accepted : .declined
            
            if accept {
                // Refresh connections list
                await fetchConnections()
            }
            
        } catch {
            handleError(error)
        }
    }
    
    func fetchPendingRequests() async {
        do {
            pendingRequests = try await connectService.getConnectionRequests()
        } catch {
            print("Failed to fetch pending requests: \(error)")
        }
    }
    
    func fetchConnections() async {
        do {
            connections = try await connectService.getConnections()
        } catch {
            print("Failed to fetch connections: \(error)")
        }
    }
    
    // MARK: - Coffee Treat
    
    func sendCoffeeTreat(to userId: String, productId: String, productName: String, message: String?) async -> Bool {
        do {
            let treat = try await connectService.sendCoffeeTreat(
                toUserId: userId,
                productId: productId,
                message: message
            )
            
            sentTreats.append(treat)
            
            // Add undo capability (cancel treat)
            undoAction = UndoableAction(
                description: "Coffee treat sent!",
                undoHandler: { [weak self] in
                    Task {
                        try? await self?.connectService.respondToCoffeeTreat(treatId: treat.id, accept: false)
                        self?.sentTreats.removeAll { $0.id == treat.id }
                    }
                }
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if self?.undoAction?.description == "Coffee treat sent!" {
                    self?.undoAction = nil
                }
            }
            
            return true
            
        } catch {
            handleError(error)
            return false
        }
    }
    
    func respondToTreat(_ treatId: String, accept: Bool) async {
        do {
            try await connectService.respondToCoffeeTreat(treatId: treatId, accept: accept)
            
            // Remove from pending
            pendingTreats.removeAll { $0.id == treatId }
            
            if accept {
                // Could trigger chat unlock here
            }
            
        } catch {
            handleError(error)
        }
    }
    
    func fetchPendingTreats() async {
        do {
            pendingTreats = try await connectService.getPendingTreats()
        } catch {
            print("Failed to fetch pending treats: \(error)")
        }
    }
    
    // MARK: - Block / Report
    
    func blockUser(_ userId: String) async {
        do {
            try await connectService.blockUser(userId: userId)
            blockedUserIds.insert(userId)
            
            // Remove from discoverable users
            discoverableUsers.removeAll { $0.userId == userId }
            
            // Add undo
            undoAction = UndoableAction(
                description: "User blocked",
                undoHandler: { [weak self] in
                    Task {
                        try? await self?.connectService.unblockUser(userId: userId)
                        self?.blockedUserIds.remove(userId)
                        await self?.fetchDiscoverableUsers()
                    }
                }
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if self?.undoAction?.description == "User blocked" {
                    self?.undoAction = nil
                }
            }
            
            persistState()
            
        } catch {
            handleError(error)
        }
    }
    
    func unblockUser(_ userId: String) async {
        do {
            try await connectService.unblockUser(userId: userId)
            blockedUserIds.remove(userId)
            persistState()
        } catch {
            handleError(error)
        }
    }
    
    func reportUser(_ userId: String, reason: ReportReason, details: String? = nil) async {
        do {
            try await connectService.reportUser(userId: userId, reason: reason, details: details)
            
            // Auto-block after reporting
            await blockUser(userId)
            
        } catch {
            handleError(error)
        }
    }
    
    func fetchBlockedUsers() async {
        do {
            let ids = try await connectService.getBlockedUsers()
            blockedUserIds = Set(ids)
            persistState()
        } catch {
            print("Failed to fetch blocked users: \(error)")
        }
    }
    
    // MARK: - Rate Limiting
    
    private func recordHandshakeRequest() {
        hourlyRequestTimestamps.append(Date())
        handshakeRequestsThisHour = hourlyRequestTimestamps.count
        persistState()
    }
    
    private func cleanOldRequests() {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        hourlyRequestTimestamps.removeAll { $0 < oneHourAgo }
        handshakeRequestsThisHour = hourlyRequestTimestamps.count
    }
    
    private func setupRateLimitReset() {
        // Reset rate limit counter every hour
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanOldRequests()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Undo Support
    
    func performUndo() {
        undoAction?.undoHandler()
        undoAction = nil
    }
    
    // MARK: - Persistence
    
    private func persistState() {
        UserDefaults.standard.set(presenceStatus.rawValue, forKey: "connect_presence_status")
        UserDefaults.standard.set(Array(blockedUserIds), forKey: "connect_blocked_users")
        
        if let timestamps = try? JSONEncoder().encode(hourlyRequestTimestamps) {
            UserDefaults.standard.set(timestamps, forKey: "connect_rate_limit_timestamps")
        }
        
        if let checkIn = currentCheckIn, let data = try? JSONEncoder().encode(checkIn) {
            UserDefaults.standard.set(data, forKey: "connect_current_checkin")
        } else {
            UserDefaults.standard.removeObject(forKey: "connect_current_checkin")
        }
    }
    
    private func loadPersistedState() {
        if let statusRaw = UserDefaults.standard.string(forKey: "connect_presence_status"),
           let status = PresenceStatus(rawValue: statusRaw) {
            presenceStatus = status
        }
        
        if let blocked = UserDefaults.standard.stringArray(forKey: "connect_blocked_users") {
            blockedUserIds = Set(blocked)
        }
        
        if let data = UserDefaults.standard.data(forKey: "connect_rate_limit_timestamps"),
           let timestamps = try? JSONDecoder().decode([Date].self, from: data) {
            hourlyRequestTimestamps = timestamps
            cleanOldRequests()
        }
        
        if let data = UserDefaults.standard.data(forKey: "connect_current_checkin"),
           let checkIn = try? JSONDecoder().decode(EnhancedCheckIn.self, from: data) {
            // Only restore if within last 4 hours (session validity)
            if checkIn.checkedInAt.addingTimeInterval(4 * 3600) > Date() {
                currentCheckIn = checkIn
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        viewState = .error(error.localizedDescription)
        errorMessage = error.localizedDescription
        showError = true
    }
    
    // MARK: - Cleanup on Account Deletion / Logout
    
    func clearAllData() {
        currentCheckIn = nil
        discoverableUsers = []
        pendingRequests = []
        connections = []
        pendingTreats = []
        sentTreats = []
        blockedUserIds = []
        connectionStatuses = [:]
        
        UserDefaults.standard.removeObject(forKey: "connect_presence_status")
        UserDefaults.standard.removeObject(forKey: "connect_blocked_users")
        UserDefaults.standard.removeObject(forKey: "connect_rate_limit_timestamps")
        UserDefaults.standard.removeObject(forKey: "connect_current_checkin")
    }
}

// MARK: - Undo Action

struct UndoableAction {
    let description: String
    let undoHandler: () -> Void
}
