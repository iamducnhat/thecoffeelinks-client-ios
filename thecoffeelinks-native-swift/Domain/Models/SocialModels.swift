//
//  SocialModels.swift
//  thecoffeelinks-native-swift
//
//  Domain models for social/connection features - NO SwiftUI imports
//

import Foundation

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
}

struct Report: Codable, Identifiable, Sendable {
    let id: String
    let reporterId: String
    let reportedUserId: String
    let reason: ReportReason
    let details: String?
    let status: ReportStatus
    let createdAt: Date
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
    
    struct CheckInPayload: Codable, Sendable { let storeId: String; let status: PresenceStatus; let mode: ConnectionMode }
    struct CheckOutPayload: Codable, Sendable { let storeId: String }
    struct StatusUpdatePayload: Codable, Sendable { let status: PresenceStatus }
    struct PresenceListPayload: Codable, Sendable { let storeId: String; let presences: [StorePresence] }
    struct UserJoinedPayload: Codable, Sendable { let presence: StorePresence }
    struct UserLeftPayload: Codable, Sendable { let userId: String; let storeId: String }
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
        case id, type, title, subtitle, description, date, storeId, hostName
        case backgroundColor = "bg"
        case iconName = "icon"
        case imageUrl = "imageURL"
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

