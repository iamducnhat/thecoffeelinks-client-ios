//
//  SocialModels.swift
//  thecoffeelinks-client-ios
//
//  Domain models for social/connection features - NO SwiftUI imports
//

import Foundation

// MARK: - Store Presence

// MARK: - Store Presence

struct StorePresence: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    let storeId: String
    let displayName: String
    let avatarUrl: String?
    let status: PresenceStatus
    let mode: ConnectionMode
    let checkedInAt: Date
    let lastActiveAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, status, mode
        case userId = "user_id"
        case storeId = "store_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case checkedInAt = "checked_in_at"
        case lastActiveAt = "last_active_at"
    }
    
    var isActive: Bool { Date().timeIntervalSince(lastActiveAt) < 300 }
}

enum PresenceStatus: String, Codable, CaseIterable, Sendable {
    case available, focused, away
    
    var displayName: String {
        switch self {
        case .available: return "Available"
        case .focused: return "Focused"
        case .away: return "Away"
        }
    }
    
    var iconName: String {
        switch self {
        case .available: return "circle.fill"
        case .focused: return "moon.fill"
        case .away: return "circle.dotted"
        }
    }
    
    var color: String {
        switch self {
        case .available: return "green"
        case .focused: return "orange"
        case .away: return "gray"
        }
    }
}

enum ConnectionMode: String, Codable, CaseIterable, Sendable {
    case open, focus
    
    var displayName: String {
        switch self {
        case .open: return "Open to Connect"
        case .focus: return "Focus Mode"
        }
    }
    
    var description: String {
        switch self {
        case .open: return "Visible to other coffee enthusiasts"
        case .focus: return "Working quietly, not open to chat"
        }
    }
}

// MARK: - Connection Request

struct ConnectionRequest: Codable, Identifiable, Sendable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let fromUserName: String
    let fromUserAvatar: String?
    let message: String?
    let status: ConnectionRequestStatus
    let createdAt: Date
    let respondedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, message, status
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case fromUserName = "from_user_name"
        case fromUserAvatar = "from_user_avatar"
        case createdAt = "created_at"
        case respondedAt = "responded_at"
    }
}

enum ConnectionRequestStatus: String, Codable, Sendable {
    case pending, accepted, declined, expired
}

// MARK: - Connection

struct Connection: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    let friendId: String
    let friendName: String
    let friendAvatar: String?
    let connectedAt: Date
    let lastInteractionAt: Date?
    var isBlocked: Bool
    var isMuted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case friendName = "friend_name"
        case friendAvatar = "friend_avatar"
        case connectedAt = "connected_at"
        case lastInteractionAt = "last_interaction_at"
        case isBlocked = "is_blocked"
        case isMuted = "is_muted"
    }
}

// MARK: - Coffee Treat

struct CoffeeTreat: Codable, Identifiable, Sendable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let fromUserName: String
    let toUserName: String
    let amount: Double
    let message: String?
    let status: TreatStatus
    let createdAt: Date
    let claimedAt: Date?
    let expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, amount, message, status
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case fromUserName = "from_user_name"
        case toUserName = "to_user_name"
        case createdAt = "created_at"
        case claimedAt = "claimed_at"
        case expiresAt = "expires_at"
    }
    
    var isExpired: Bool { Date() > expiresAt }
}

enum TreatStatus: String, Codable, Sendable {
    case pending, claimed, expired, cancelled
}

// MARK: - Block / Report

struct BlockedUser: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    let blockedUserId: String
    let blockedUserName: String
    let reason: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, reason
        case userId = "user_id"
        case blockedUserId = "blocked_user_id"
        case blockedUserName = "blocked_user_name"
        case createdAt = "created_at"
    }
}

struct Report: Codable, Identifiable, Sendable {
    let id: String
    let reporterId: String
    let reportedUserId: String
    let reason: ReportReason
    let details: String?
    let status: ReportStatus
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, reason, details, status
        case reporterId = "reporter_id"
        case reportedUserId = "reported_user_id"
        case createdAt = "created_at"
    }
}

enum ReportReason: String, Codable, CaseIterable, Sendable {
    case harassment, spam, inappropriate, impersonation, other
    
    var displayName: String {
        switch self {
        case .harassment: return "Harassment or Bullying"
        case .spam: return "Spam"
        case .inappropriate: return "Inappropriate Content"
        case .impersonation: return "Impersonation"
        case .other: return "Other"
        }
    }
}

enum ReportStatus: String, Codable, Sendable {
    case submitted, reviewing, resolved, dismissed
}

// MARK: - Presence WebSocket Messages

enum PresenceMessage: Codable, Sendable {
    case checkIn(CheckInPayload)
    case checkOut(CheckOutPayload)
    case statusUpdate(StatusUpdatePayload)
    case presenceList(PresenceListPayload)
    case userJoined(UserJoinedPayload)
    case userLeft(UserLeftPayload)
    
    // Note: Websocket payloads might differ, but assuming snake_case consistent with server
    struct CheckInPayload: Codable, Sendable { 
        let storeId: String; let status: PresenceStatus; let mode: ConnectionMode 
        enum CodingKeys: String, CodingKey { case storeId = "store_id"; case status, mode }
    }
    struct CheckOutPayload: Codable, Sendable { 
        let storeId: String 
        enum CodingKeys: String, CodingKey { case storeId = "store_id" }
    }
    struct StatusUpdatePayload: Codable, Sendable { let status: PresenceStatus }
    struct PresenceListPayload: Codable, Sendable { 
        let storeId: String; let presences: [StorePresence] 
        enum CodingKeys: String, CodingKey { case storeId = "store_id"; case presences }
    }
    struct UserJoinedPayload: Codable, Sendable { let presence: StorePresence }
    struct UserLeftPayload: Codable, Sendable { 
        let userId: String; let storeId: String 
        enum CodingKeys: String, CodingKey { case userId = "user_id"; case storeId = "store_id" }
    }
}

// MARK: - Events

struct Event: Codable, Identifiable, Sendable {
    let id: String
    let type: EventType
    let title: String
    let subtitle: String?
    let description: String?
    let date: Date?
    let storeId: String?
    let hostName: String?
    let backgroundColor: String?
    let iconName: String?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, subtitle, description, date
        case storeId = "store_id"
        case hostName = "host_name"
        case backgroundColor = "bg"
        case iconName = "icon"
        case imageUrl = "image_url"
    }
    
    var isPromotion: Bool { type == .promotion }
}

enum EventType: String, Codable, Sendable {
    case promotion, announcement, networking, workshop, other
    
    var iconSystemName: String {
        switch self {
        case .promotion: return "percent"
        case .announcement: return "megaphone.fill"
        case .networking: return "person.3.fill"
        case .workshop: return "hammer.fill"
        case .other: return "star.fill"
        }
    }
}

// MARK: - API Responses

struct EventsResponse: Codable, Sendable {
    let events: [Event]
}

struct PresenceResponse: Codable, Sendable { let success: Bool; let presences: [StorePresence] }
struct ConnectionsResponse: Codable, Sendable { let success: Bool; let connections: [Connection] }
struct BlockResponse: Codable, Sendable { let success: Bool; let blocked: BlockedUser?; let message: String? }
struct ReportResponse: Codable, Sendable { let success: Bool; let report: Report?; let message: String? }
struct TreatsResponse: Codable, Sendable { let success: Bool; let treats: [CoffeeTreat] }

