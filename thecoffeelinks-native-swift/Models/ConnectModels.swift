//
//  ConnectModels.swift
//  thecoffeelinks-native-swift
//
//  Core models for Connect/Networking feature
//

import Foundation

// MARK: - Presence Status

enum PresenceStatus: String, Codable, CaseIterable {
    case focusMode = "focus"       // Invisible, no discovery
    case openToNetwork = "open"    // Discoverable
    
    var displayName: String {
        switch self {
        case .focusMode: return "Focus Mode"
        case .openToNetwork: return "Open to Network"
        }
    }
    
    var description: String {
        switch self {
        case .focusMode: return "You're invisible. Perfect for deep work."
        case .openToNetwork: return "Others can discover you and connect."
        }
    }
    
    var icon: String {
        switch self {
        case .focusMode: return "moon.fill"
        case .openToNetwork: return "person.wave.2.fill"
        }
    }
}

// MARK: - Networking Intent

enum NetworkingIntent: String, Codable, CaseIterable, Identifiable {
    case mentor = "mentor"
    case hiring = "hiring"
    case sales = "sales"
    case learn = "learn"
    case collaborate = "collaborate"
    case justCoffee = "just_coffee"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .mentor: return "Mentoring"
        case .hiring: return "Hiring"
        case .sales: return "Business"
        case .learn: return "Learning"
        case .collaborate: return "Collaboration"
        case .justCoffee: return "Just Coffee"
        }
    }
    
    var icon: String {
        switch self {
        case .mentor: return "lightbulb.fill"
        case .hiring: return "briefcase.fill"
        case .sales: return "chart.line.uptrend.xyaxis"
        case .learn: return "book.fill"
        case .collaborate: return "person.2.fill"
        case .justCoffee: return "cup.and.saucer.fill"
        }
    }
    
    var color: String {
        switch self {
        case .mentor: return "yellow"
        case .hiring: return "blue"
        case .sales: return "green"
        case .learn: return "purple"
        case .collaborate: return "orange"
        case .justCoffee: return "brown"
        }
    }
}

// MARK: - Connection Request

enum ConnectionStatus: String, Codable {
    case none = "none"
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case blocked = "blocked"
}

struct ConnectionRequest: Codable, Identifiable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let status: ConnectionStatus
    let message: String?
    let createdAt: Date
    let updatedAt: Date?
    let fromUser: NetworkUser?
    let toUser: NetworkUser?
}

// MARK: - Network User (Extended Profile for Discovery)

struct NetworkUser: Codable, Identifiable {
    let id: String
    let fullName: String?
    let avatarUrl: String?
    let jobTitle: String?
    let company: String?
    let industry: String?
    let bio: String?
    let linkedinUrl: String?
    let intents: [NetworkingIntent]?
    let isVerified: Bool?
    
    // Computed for display
    var displayName: String {
        fullName ?? "Coffee Lover"
    }
    
    var headline: String {
        if let job = jobTitle, let company = company {
            return "\(job) at \(company)"
        } else if let job = jobTitle {
            return job
        } else if let company = company {
            return company
        }
        return ""
    }
    
    var initials: String {
        guard let name = fullName else { return "?" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(1))
    }
}

// MARK: - Check-In Store Info (Simple version for Codable)

struct CheckInStoreInfo: Codable {
    let id: String
    let name: String
    let address: String
    let imageUrl: String?
}

// MARK: - Check-In (Enhanced)

struct EnhancedCheckIn: Codable, Identifiable {
    let id: String
    let userId: String
    let storeId: String
    let status: PresenceStatus
    let checkedInAt: Date
    let checkedOutAt: Date?
    let user: NetworkUser?
    let store: CheckInStoreInfo?
    
    var isActive: Bool {
        checkedOutAt == nil
    }
    
    var durationMinutes: Int {
        let end = checkedOutAt ?? Date()
        return Int(end.timeIntervalSince(checkedInAt) / 60)
    }
}

// MARK: - Coffee Treat

enum CoffeeTreatStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
    case cancelled = "cancelled"
}

struct CoffeeTreat: Codable, Identifiable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let productId: String
    let productName: String
    let productPrice: Double
    let message: String?
    let status: CoffeeTreatStatus
    let createdAt: Date
    let expiresAt: Date
    let acceptedAt: Date?
    let fromUser: NetworkUser?
    let toUser: NetworkUser?
    
    var isExpired: Bool {
        Date() > expiresAt && status == .pending
    }
}

// MARK: - Rate Limit Tracker

struct RateLimitInfo {
    let requestsRemaining: Int
    let resetTime: Date
    let maxRequests: Int
    
    var isLimited: Bool {
        requestsRemaining <= 0 && Date() < resetTime
    }
    
    var timeUntilReset: TimeInterval {
        max(0, resetTime.timeIntervalSince(Date()))
    }
}

// MARK: - Report Reason

enum ReportReason: String, CaseIterable, Identifiable {
    case spam = "spam"
    case harassment = "harassment"
    case inappropriate = "inappropriate"
    case fake = "fake_profile"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .spam: return "Spam or Scam"
        case .harassment: return "Harassment"
        case .inappropriate: return "Inappropriate Behavior"
        case .fake: return "Fake Profile"
        case .other: return "Other"
        }
    }
}

// MARK: - Digital Business Card

struct DigitalBusinessCard: Codable {
    let userId: String
    let fullName: String
    let jobTitle: String?
    let company: String?
    let email: String?
    let phone: String?
    let linkedinUrl: String?
    let websiteUrl: String?
    let bio: String?
    let avatarUrl: String?
    let qrCodeData: String? // For generating QR
}
