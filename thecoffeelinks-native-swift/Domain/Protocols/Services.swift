//
//  Services.swift
//  thecoffeelinks-native-swift
//
//  Service protocols - NO SwiftUI imports
//

import Foundation

// MARK: - Network Service

protocol NetworkServiceProtocol: Sendable {
    func get<T: Decodable>(_ endpoint: String, queryItems: [URLQueryItem]?) async throws -> T
    func post<T: Decodable, U: Encodable>(_ endpoint: String, body: U) async throws -> T
    func put<T: Decodable, U: Encodable>(_ endpoint: String, body: U) async throws -> T
    func patch<T: Decodable, U: Encodable>(_ endpoint: String, body: U) async throws -> T
    func delete(_ endpoint: String, queryItems: [URLQueryItem]?) async throws
}

// MARK: - Auth Service

protocol AuthServiceProtocol: Sendable {
    var isAuthenticated: Bool { get async }
    var currentSession: AuthSession? { get async }
    
    func login(email: String, password: String) async throws -> AuthSession
    func loginWithApple(identityToken: String) async throws -> AuthSession
    func loginWithPhone(phone: String, otp: String) async throws -> AuthSession
    func requestOTP(phone: String) async throws
    func logout() async throws
    func refreshTokenIfNeeded() async throws
}

// MARK: - Location Service

protocol LocationServiceProtocol: Sendable {
    var currentLocation: (latitude: Double, longitude: Double)? { get async }
    var authorizationStatus: LocationAuthorizationStatus { get async }
    
    func requestAuthorization() async
    func startUpdatingLocation() async
    func stopUpdatingLocation() async
    func geocodeAddress(_ address: String) async throws -> (latitude: Double, longitude: Double)
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String
}

enum LocationAuthorizationStatus: Sendable {
    case notDetermined, restricted, denied, authorizedWhenInUse, authorizedAlways
}

// MARK: - Presence Service (WebSocket)

protocol PresenceServiceProtocol: Sendable {
    var isConnected: Bool { get async }
    
    func connect(storeId: String) async throws
    func disconnect() async
    func checkIn(status: PresenceStatus, mode: PresenceMode) async throws
    func checkOut() async throws
    func updateStatus(_ status: PresenceStatus) async throws
}

// MARK: - Notification Service

protocol NotificationServiceProtocol: Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleOrderReady(orderId: String, message: String) async
    func scheduleDeliveryUpdate(orderId: String, status: DeliveryTrackingStatus) async
    func cancelNotification(id: String) async
}

// MARK: - Analytics Service

protocol AnalyticsServiceProtocol: Sendable {
    func trackEvent(_ name: String, properties: [String: Any]?) async
    func trackScreen(_ name: String) async
    func setUserProperty(_ name: String, value: String?) async
    func trackPurchase(orderId: String, amount: Double, items: [OrderItem]) async
}

// MARK: - Cache Service

protocol CacheServiceProtocol: Sendable {
    func get<T: Codable>(_ key: String) async -> T?
    func getEntry<T: Codable>(_ key: String) async -> (value: T, isExpired: Bool)?
    func set<T: Codable>(_ key: String, value: T, ttl: TimeInterval?) async
    func remove(_ key: String) async
    func clear() async
}

// MARK: - Haptic Service

protocol HapticServiceProtocol: Sendable {
    func impact(_ style: HapticStyle) async
    func notification(_ type: HapticNotificationType) async
    func selection() async
}

enum HapticStyle: Sendable { case light, medium, heavy, soft, rigid }
enum HapticNotificationType: Sendable { case success, warning, error }

// MARK: - Secure Storage

protocol SecureStorage: Sendable {
    func get(_ key: String) -> String?
    func set(_ key: String, value: String)
    func remove(_ key: String)
}
