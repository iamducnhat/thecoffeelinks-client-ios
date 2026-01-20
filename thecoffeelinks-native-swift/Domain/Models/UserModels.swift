//
//  UserModels.swift
//  thecoffeelinks-native-swift
//
//  Domain models for users - NO SwiftUI imports
//

import Foundation

// MARK: - User

struct User: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let shortId: String?
    let shortIdVersion: Int?
    let email: String?
    let phone: String?
    let displayName: String
    let avatarUrl: String?
    let membershipTier: MembershipTier
    let points: Int
    let createdAt: Date
    var preferences: UserPreferences
    
    var fullName: String { displayName } // UI Compatibility
    var bio: String? { nil } // UI Compatibility (Phase 6 Profile)
    var jobTitle: String? { nil } // UI Compatibility
    var linkedinProfile: String? { nil } // UI Compatibility
    
    enum CodingKeys: String, CodingKey {
        case id
        case shortId = "short_id"
        case shortIdVersion = "short_id_version"
        case email, phone
        case displayName = "name"
        case avatarUrl = "avatar_url"
        case membershipTier = "membership_tier"
        case points
        case createdAt = "member_since"
        case preferences
    }
    
    init(id: String, shortId: String? = nil, shortIdVersion: Int? = 1, email: String?, phone: String?, displayName: String,
         avatarUrl: String?, membershipTier: MembershipTier, points: Int,
         createdAt: Date, preferences: UserPreferences) {
        self.id = id
        self.shortId = shortId
        self.shortIdVersion = shortIdVersion
        self.email = email
        self.phone = phone
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.membershipTier = membershipTier
        self.points = points
        self.createdAt = createdAt
        self.preferences = preferences
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        
        // Helper Key for dynamic lookup
        struct AnyKey: CodingKey {
            var stringValue: String
            init?(stringValue: String) { self.stringValue = stringValue }
            var intValue: Int?
            init?(intValue: Int) { return nil }
        }
        
        // 1. Try decoding shortId from top-level (String or Int) via standard Key (short_id)
        var mainShortId: String? = try container.decodeIfPresent(String.self, forKey: .shortId)
        if mainShortId == nil {
            if let intId = try? container.decodeIfPresent(Int.self, forKey: .shortId) {
                mainShortId = String(intId)
            }
        }
        
        // 1b. Fallback: Try top-level "shortId" (camelCase) if "short_id" was missing
        if mainShortId == nil {
            if let anyContainer = try? decoder.container(keyedBy: AnyKey.self) {
                if let sidCamel = try? anyContainer.decodeIfPresent(String.self, forKey: AnyKey(stringValue: "shortId")!) {
                    mainShortId = sidCamel
                } else if let sidCamelInt = try? anyContainer.decodeIfPresent(Int.self, forKey: AnyKey(stringValue: "shortId")!) {
                    mainShortId = String(sidCamelInt)
                }
            }
        }
        
        // 2. If nil, try decoding from user_metadata
        if let sid = mainShortId {
            shortId = sid
        } else {
            var foundShortId: String? = nil
            
            if let paramsContainer = try? decoder.container(keyedBy: AnyKey.self) {
                 if let metaKey = AnyKey(stringValue: "user_metadata"),
                    let metaContainer = try? paramsContainer.nestedContainer(keyedBy: AnyKey.self, forKey: metaKey) {
                    
                    // Try short_id (String then Int)
                    if let sid = try? metaContainer.decodeIfPresent(String.self, forKey: AnyKey(stringValue: "short_id")!) {
                        foundShortId = sid
                    } else if let sidInt = try? metaContainer.decodeIfPresent(Int.self, forKey: AnyKey(stringValue: "short_id")!) {
                        foundShortId = String(sidInt)
                    }
                    
                    // Try shortId (String then Int)
                    if foundShortId == nil {
                        if let sidCamel = try? metaContainer.decodeIfPresent(String.self, forKey: AnyKey(stringValue: "shortId")!) {
                            foundShortId = sidCamel
                        } else if let sidCamelInt = try? metaContainer.decodeIfPresent(Int.self, forKey: AnyKey(stringValue: "shortId")!) {
                            foundShortId = String(sidCamelInt)
                        }
                    }
                }
            }
            
            shortId = foundShortId
        }
        
        shortIdVersion = try container.decodeIfPresent(Int.self, forKey: .shortIdVersion)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        let rawName = try container.decode(String.self, forKey: .displayName)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        
        // Fix for "Hello, User" issue:
        // If the name is generic "User" (case-insensitive) or empty, and we have a phone number,
        // prefer showing the phone number to match the initial login experience.
        if (rawName.isEmpty || rawName.caseInsensitiveCompare("user") == .orderedSame),
           let phoneIdx = phone, !phoneIdx.isEmpty {
            displayName = phoneIdx
        } else {
            displayName = rawName
        }
        
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        points = try container.decodeIfPresent(Int.self, forKey: .points) ?? 0
        
        // Safe decoding for dates with fallback
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let iso = ISO8601DateFormatter()
             // Handle fractional seconds if present
             iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
             if let date = iso.date(from: dateString) {
                 createdAt = date
             } else {
                 // Try without fractional seconds
                 iso.formatOptions = [.withInternetDateTime]
                 createdAt = iso.date(from: dateString) ?? Date()
             }
        } else {
            createdAt = Date()
        }
        
        // Safe decoding for enums/objects that might be missing
        membershipTier = try container.decodeIfPresent(MembershipTier.self, forKey: .membershipTier) ?? .bronze
        preferences = try container.decodeIfPresent(UserPreferences.self, forKey: .preferences) ?? .default
    }
    
    static func == (lhs: User, rhs: User) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    static var placeholder: User {
        User(id: "placeholder", shortId: "123456", shortIdVersion: 1, email: nil, phone: nil, displayName: "User",
             avatarUrl: nil, membershipTier: .bronze, points: 0,
             createdAt: Date(), preferences: .default)
    }
}

// MARK: - Membership Tier

enum MembershipTier: String, Codable, CaseIterable, Sendable {
    case bronze, silver, gold, platinum
    
    var displayName: String { rawValue.capitalized }
    
    var pointsMultiplier: Double {
        switch self {
        case .bronze: return 1.0
        case .silver: return 1.25
        case .gold: return 1.5
        case .platinum: return 2.0
        }
    }
    
    var discountPercentage: Double {
        switch self {
        case .bronze: return 0
        case .silver: return 5
        case .gold: return 10
        case .platinum: return 15
        }
    }
}

// MARK: - User Preferences

struct UserPreferences: Codable, Hashable, Sendable {
    var defaultOrderingMode: OrderingMode
    var defaultStoreId: String?
    var defaultPaymentMethod: PaymentMethod?
    var defaultSize: ProductSize
    var defaultSugar: SugarLevel?
    var defaultIce: IceLevel?
    var notificationsEnabled: Bool
    var orderUpdatesEnabled: Bool
    var promotionsEnabled: Bool
    enum CodingKeys: String, CodingKey {
        case defaultOrderingMode = "default_ordering_mode"
        case defaultStoreId = "default_store_id"
        case defaultPaymentMethod = "default_payment_method"
        case defaultSize = "default_size"
        case defaultSugar = "default_sugar"
        case defaultIce = "default_ice"
        case notificationsEnabled = "notifications_enabled"
        case orderUpdatesEnabled = "order_updates_enabled"
        case promotionsEnabled = "promotions_enabled"
        case presenceMode = "presence_mode"
    }
    
    static var `default`: UserPreferences {
        UserPreferences(
            defaultOrderingMode: .pickup, defaultStoreId: nil,
            defaultPaymentMethod: .applePay, defaultSize: .medium,
            defaultSugar: .half, defaultIce: .normal,
            notificationsEnabled: true, orderUpdatesEnabled: true,
            promotionsEnabled: false, presenceMode: .private
        )
    }
}

// MARK: - Presence Mode

enum PresenceMode: String, Codable, CaseIterable, Sendable {
    case `private`, friends, `public`
    
    var displayName: String {
        switch self {
        case .private: return "Private"
        case .friends: return "Friends Only"
        case .public: return "Public"
        }
    }
    
    var description: String {
        switch self {
        case .private: return "Your presence is hidden from everyone"
        case .friends: return "Only friends can see when you're at a store"
        case .public: return "Anyone at the store can see you're there"
        }
    }
    
    var allowsPublicVisibility: Bool { self == .public }
    var allowsFriendVisibility: Bool { self == .public || self == .friends }
    
    func canBeSeenBy(viewer: User, isConnection: Bool) -> Bool {
        switch self {
        case .private: return false
        case .friends: return isConnection
        case .public: return true
        }
    }
}

// MARK: - Favorite Item

struct FavoriteItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let userId: String
    let product: Product
    let customization: OrderCustomization
    let nickname: String?
    let notes: String?
    let orderCount: Int
    let lastOrderedAt: Date?
    let createdAt: Date
    
    var displayName: String { nickname ?? product.name }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case product, customization, nickname, notes
        case orderCount = "order_count"
        case lastOrderedAt = "last_ordered_at"
        case createdAt = "created_at"
    }
    
    static func == (lhs: FavoriteItem, rhs: FavoriteItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Store

struct Store: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let phone: String?
    let imageUrl: String?
    let layoutMapUrl: String? // Phase 3 Space Feature
    let openingHours: [OpeningHour]?
    let amenities: [StoreAmenity]?
    let isOpen: Bool?
    let isBusy: Bool?
    let currentWaitMinutes: Int?
    let deliveryAvailable: Bool?
    let pickupAvailable: Bool?
    let dineInAvailable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude, longitude, phone
        case imageUrl = "image_url"
        case layoutMapUrl = "layout_map_url"
        case openingHours = "opening_hours"
        case amenities
        case isOpen = "is_open"
        case isBusy = "is_busy"
        case currentWaitMinutes = "current_wait_minutes"
        case deliveryAvailable = "delivery_available"
        case pickupAvailable = "pickup_available"
        case dineInAvailable = "dine_in_available"
    }
    
    var isCurrentlyOpen: Bool {
        guard let openingHours = openingHours else { return false }
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        guard let todayHours = openingHours.first(where: { $0.dayOfWeek == weekday }) else { return false }
        return currentMinutes >= todayHours.openMinutes && currentMinutes <= todayHours.closeMinutes
    }
    
    static func == (lhs: Store, rhs: Store) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct OpeningHour: Codable, Hashable, Sendable {
    let dayOfWeek: Int
    let openMinutes: Int
    let closeMinutes: Int
    
    var openTime: String { formatMinutes(openMinutes) }
    var closeTime: String { formatMinutes(closeMinutes) }
    
    private func formatMinutes(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
    
    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case openMinutes = "open_minutes"
        case closeMinutes = "close_minutes"
    }
}

enum StoreAmenity: String, Codable, CaseIterable, Sendable {
    case wifi, parking
    case powerOutlets = "power_outlets"
    case wheelchairAccessible = "wheelchair_accessible"
    case outdoorSeating = "outdoor_seating"
    case driveThrough = "drive_through"
    
    var displayName: String {
        switch self {
        case .wifi: return "WiFi"
        case .parking: return "Parking"
        case .powerOutlets: return "Power Outlets"
        case .wheelchairAccessible: return "Wheelchair Accessible"
        case .outdoorSeating: return "Outdoor Seating"
        case .driveThrough: return "Drive Through"
        }
    }
    
    var iconName: String {
        switch self {
        case .wifi: return "wifi"
        case .parking: return "car.fill"
        case .powerOutlets: return "poweroutlet.type.b"
        case .wheelchairAccessible: return "figure.roll"
        case .outdoorSeating: return "sun.max"
        case .driveThrough: return "car.side"
        }
    }
}

// MARK: - Auth

struct AuthSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }
    
    var isExpired: Bool { Date() >= expiresAt }
    var shouldRefresh: Bool { Date().addingTimeInterval(5 * 60) >= expiresAt }
}

struct LoginRequest: Codable, Sendable {
    let email: String?
    let phone: String?
    let password: String?
    let otp: String?
    let provider: AuthProvider?
}

enum AuthProvider: String, Codable, Sendable {
    case email, phone, apple, google
}

struct AuthResponse: Codable, Sendable {
    let success: Bool
    let session: AuthSession?
    let message: String?
    let requiresVerification: Bool?
}

// MARK: - API Responses

struct UserResponse: Codable, Sendable { let success: Bool; let user: User }
struct StoresResponse: Codable, Sendable { let success: Bool; let stores: [Store] }
struct StoreResponse: Codable, Sendable { let success: Bool; let store: Store }
struct FavoritesResponse: Codable, Sendable { let success: Bool; let favorites: [FavoriteItem] }
struct FavoriteResponse: Codable, Sendable { let success: Bool; let favorite: FavoriteItem }
struct PreferencesResponse: Codable, Sendable { let success: Bool; let preferences: UserPreferences }
struct EmptyResponse: Codable, Sendable { let success: Bool }
