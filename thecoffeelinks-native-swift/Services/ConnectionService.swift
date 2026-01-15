//
//  ConnectionService.swift
//  thecoffeelinks-native-swift
//
//  Connection system for The Coffee Links.
//  NOT a social network — passive trust signals only.
//

import Foundation
import Combine

// MARK: - Connection Mode

enum ConnectionMode: String, Codable, CaseIterable {
    case openToConnect = "open"
    case focusMode = "focus"
    
    var displayTitle: String {
        switch self {
        case .openToConnect: return "Open to Connect"
        case .focusMode: return "Focus Mode"
        }
    }
    
    var displaySubtitle: String {
        switch self {
        case .openToConnect: return "Visible to others at this store"
        case .focusMode: return "Invisible to others, heads down"
        }
    }
    
    var iconName: String {
        switch self {
        case .openToConnect: return "person.2.fill"
        case .focusMode: return "headphones"
        }
    }
}

// MARK: - Blocked User

struct BlockedUser: Codable, Identifiable {
    let id: String
    let userId: String
    let blockedAt: Date
    let reason: BlockReason?
}

enum BlockReason: String, Codable, CaseIterable {
    case spam = "spam"
    case harassment = "harassment"
    case inappropriate = "inappropriate"
    case other = "other"
    
    var displayText: String {
        switch self {
        case .spam: return "Spam or scam"
        case .harassment: return "Harassment"
        case .inappropriate: return "Inappropriate behavior"
        case .other: return "Other"
        }
    }
}

// MARK: - Connection Presence

struct StorePresence: Identifiable {
    let id: String // userId
    let name: String
    let avatarUrl: String?
    let isConnectedWithMe: Bool // Have we connected before?
    let isMutedByMe: Bool
}

// MARK: - Connection Service

@MainActor
class ConnectionService: ObservableObject {
    static let shared = ConnectionService()
    
    // User's current connection mode
    @Published var connectionMode: ConnectionMode {
        didSet {
            UserDefaults.standard.set(connectionMode.rawValue, forKey: Keys.connectionMode)
            Task { await syncModeToServer() }
        }
    }
    
    // Blocked users (invisible forever)
    @Published private(set) var blockedUserIds: Set<String> = []
    
    // Muted users (hidden updates, they don't know)
    @Published private(set) var mutedUserIds: Set<String> = []
    
    // Who's at current store (only populated if Open to Connect)
    @Published private(set) var storePresence: [StorePresence] = []
    
    // Count of regulars at store (always available)
    @Published private(set) var regularsAtStoreCount: Int = 0
    
    // Connected users at store (people you've met before)
    @Published private(set) var connectedUsersAtStore: [StorePresence] = []
    
    private enum Keys {
        static let connectionMode = "connection_mode"
        static let blockedUsers = "blocked_users"
        static let mutedUsers = "muted_users"
    }
    
    private init() {
        // Load connection mode
        if let modeRaw = UserDefaults.standard.string(forKey: Keys.connectionMode),
           let mode = ConnectionMode(rawValue: modeRaw) {
            self.connectionMode = mode
        } else {
            self.connectionMode = .focusMode // Default to private
        }
        
        // Load blocked users
        if let data = UserDefaults.standard.data(forKey: Keys.blockedUsers),
           let blocked = try? JSONDecoder().decode([BlockedUser].self, from: data) {
            self.blockedUserIds = Set(blocked.map { $0.userId })
        }
        
        // Load muted users
        if let muted = UserDefaults.standard.stringArray(forKey: Keys.mutedUsers) {
            self.mutedUserIds = Set(muted)
        }
    }
    
    // MARK: - Public Actions
    
    /// Block a user — they become invisible forever
    func blockUser(userId: String, reason: BlockReason?) {
        blockedUserIds.insert(userId)
        
        // Also mute them
        mutedUserIds.insert(userId)
        
        // Persist
        let blockedUser = BlockedUser(
            id: UUID().uuidString,
            userId: userId,
            blockedAt: Date(),
            reason: reason
        )
        saveBlockedUser(blockedUser)
        
        // Remove from presence
        storePresence.removeAll { $0.id == userId }
        connectedUsersAtStore.removeAll { $0.id == userId }
        
        // Report to server (async, non-blocking)
        Task {
            await reportBlockToServer(userId: userId, reason: reason)
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    /// Unblock a user
    func unblockUser(userId: String) {
        blockedUserIds.remove(userId)
        removeBlockedUserFromStorage(userId)
    }
    
    /// Mute a user — hide their updates, they don't know
    func muteUser(userId: String) {
        mutedUserIds.insert(userId)
        saveMutedUsers()
    }
    
    /// Unmute a user
    func unmuteUser(userId: String) {
        mutedUserIds.remove(userId)
        saveMutedUsers()
    }
    
    /// Report a user (block + flag for review)
    func reportUser(userId: String, reason: BlockReason) {
        blockUser(userId: userId, reason: reason)
        
        // Additional report action
        Task {
            await sendReportToServer(userId: userId, reason: reason)
        }
    }
    
    /// Check if a user should be visible (not blocked)
    func isUserVisible(_ userId: String) -> Bool {
        !blockedUserIds.contains(userId)
    }
    
    /// Check if a user's updates should be shown (not muted)
    func shouldShowUpdates(for userId: String) -> Bool {
        !mutedUserIds.contains(userId)
    }
    
    // MARK: - Presence
    
    /// Fetch who's at the current store
    func fetchStorePresence(storeId: String) async {
        // Only fetch if user is Open to Connect
        guard connectionMode == .openToConnect else {
            storePresence = []
            return
        }
        
        do {
            // Server call to get presence
            let presence = try await getPresenceFromServer(storeId: storeId)
            
            // Filter out blocked users
            storePresence = presence.filter { isUserVisible($0.id) }
            
            // Extract connected users
            connectedUsersAtStore = storePresence.filter { $0.isConnectedWithMe && !$0.isMutedByMe }
            
            // Count regulars (server provides this even for focus mode)
            regularsAtStoreCount = storePresence.count
        } catch {
            print("Failed to fetch store presence: \(error)")
        }
    }
    
    /// Get passive signal text for Home
    func getPresenceSignal() -> (connectedNames: [String], regularsCount: Int) {
        let names = connectedUsersAtStore.map { $0.name }
        return (names, regularsAtStoreCount)
    }
    
    // MARK: - Private
    
    private func saveBlockedUser(_ user: BlockedUser) {
        var existing: [BlockedUser] = []
        if let data = UserDefaults.standard.data(forKey: Keys.blockedUsers),
           let decoded = try? JSONDecoder().decode([BlockedUser].self, from: data) {
            existing = decoded
        }
        existing.append(user)
        if let encoded = try? JSONEncoder().encode(existing) {
            UserDefaults.standard.set(encoded, forKey: Keys.blockedUsers)
        }
    }
    
    private func removeBlockedUserFromStorage(_ userId: String) {
        guard let data = UserDefaults.standard.data(forKey: Keys.blockedUsers),
              var existing = try? JSONDecoder().decode([BlockedUser].self, from: data) else { return }
        existing.removeAll { $0.userId == userId }
        if let encoded = try? JSONEncoder().encode(existing) {
            UserDefaults.standard.set(encoded, forKey: Keys.blockedUsers)
        }
    }
    
    private func saveMutedUsers() {
        UserDefaults.standard.set(Array(mutedUserIds), forKey: Keys.mutedUsers)
    }
    
    private func syncModeToServer() async {
        // POST /api/social/presence/mode
        // Body: { mode: "open" | "focus" }
        // Non-critical, fire-and-forget
    }
    
    private func reportBlockToServer(userId: String, reason: BlockReason?) async {
        // POST /api/social/block
        // Body: { targetUserId, reason }
    }
    
    private func sendReportToServer(userId: String, reason: BlockReason) async {
        // POST /api/social/report
        // Body: { targetUserId, reason }
        // This flags for admin review
    }
    
    private func getPresenceFromServer(storeId: String) async throws -> [StorePresence] {
        // GET /api/social/presence?storeId=X
        // Returns list of users at store
        
        // Mock for now
        return []
    }
}

// MARK: - Extension for UI

extension ConnectionService {
    /// Get the display state for connection toggle
    var isOpenToConnect: Bool {
        get { connectionMode == .openToConnect }
        set { connectionMode = newValue ? .openToConnect : .focusMode }
    }
}
