//
//  CoreServices.swift
//  thecoffeelinks-client-ios
//
//  Core service implementations
//

import Foundation
import CoreLocation
import UserNotifications
import UIKit

// MARK: - Auth Request Types (Private)

private struct AppleLoginRequest: Codable, Sendable { let identityToken: String }
private struct OTPRequestBody: Codable, Sendable { let phone: String }
private struct RefreshRequestBody: Codable, Sendable { let refreshToken: String }

// MARK: - Auth Service

final class AuthService: AuthServiceProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    private let storage: SecureStorage
    private var _currentSession: AuthSession?
    
    var isAuthenticated: Bool { get async { _currentSession != nil && !(_currentSession?.isExpired ?? true) } }
    var currentSession: AuthSession? { get async { _currentSession } }
    
    init(networkService: NetworkServiceProtocol, storage: SecureStorage) {
        self.networkService = networkService
        self.storage = storage
        loadStoredSession()
    }
    
    func login(email: String, password: String) async throws -> AuthSession {
        let request = LoginRequest(email: email, phone: nil, password: password, otp: nil, provider: .email)
        let response: AuthResponse = try await networkService.post("api/auth/login", body: request)
        guard let session = response.session else { throw AuthError.loginFailed(response.message ?? "Login failed") }
        _currentSession = session
        saveSession(session)
        return session
    }
    
    func loginWithApple(identityToken: String) async throws -> AuthSession {
        let response: AuthResponse = try await networkService.post("api/auth/apple", body: AppleLoginRequest(identityToken: identityToken))
        guard let session = response.session else { throw AuthError.loginFailed(response.message ?? "Apple login failed") }
        _currentSession = session
        saveSession(session)
        return session
    }
    
    func loginWithPhone(phone: String, otp: String) async throws -> AuthSession {
        let request = LoginRequest(email: nil, phone: phone, password: nil, otp: otp, provider: .phone)
        let response: AuthResponse = try await networkService.post("api/auth/verify-otp", body: request)
        guard let session = response.session else { throw AuthError.loginFailed(response.message ?? "OTP verification failed") }
        _currentSession = session
        saveSession(session)
        return session
    }
    
    func requestOTP(phone: String) async throws {
        let _: AuthResponse = try await networkService.post("api/auth/request-otp", body: OTPRequestBody(phone: phone))
    }
    
    func logout() async throws {
        _currentSession = nil
        storage.remove("auth_session")
    }
    
    func refreshTokenIfNeeded() async throws {
        guard let session = _currentSession, session.shouldRefresh else { return }
        let response: AuthResponse = try await networkService.post("api/auth/refresh", body: RefreshRequestBody(refreshToken: session.refreshToken))
        if let newSession = response.session { _currentSession = newSession; saveSession(newSession) }
    }
    
    private func loadStoredSession() {
        guard let data = storage.get("auth_session")?.data(using: .utf8),
              let session = try? JSONDecoder().decode(AuthSession.self, from: data), !session.isExpired else { return }
        _currentSession = session
    }
    
    private func saveSession(_ session: AuthSession) {
        if let data = try? JSONEncoder().encode(session), let string = String(data: data, encoding: .utf8) {
            storage.set("auth_session", value: string)
        }
    }
}

enum AuthError: LocalizedError {
    case loginFailed(String), sessionExpired, invalidCredentials
    var errorDescription: String? {
        switch self {
        case .loginFailed(let msg): return msg
        case .sessionExpired: return "Session expired"
        case .invalidCredentials: return "Invalid credentials"
        }
    }
}

// MARK: - Location Service

final class LocationService: NSObject, LocationServiceProtocol, @unchecked Sendable {
    private let locationManager = CLLocationManager()
    private var _currentLocation: (latitude: Double, longitude: Double)?
    private var _authorizationStatus: LocationAuthorizationStatus = .notDetermined
    
    var currentLocation: (latitude: Double, longitude: Double)? { get async { _currentLocation } }
    var authorizationStatus: LocationAuthorizationStatus { get async { _authorizationStatus } }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        updateAuthorizationStatus()
    }
    
    func requestAuthorization() async { locationManager.requestWhenInUseAuthorization() }
    func startUpdatingLocation() async { locationManager.startUpdatingLocation() }
    func stopUpdatingLocation() async { locationManager.stopUpdatingLocation() }
    
    func geocodeAddress(_ address: String) async throws -> (latitude: Double, longitude: Double) {
        let placemarks = try await CLGeocoder().geocodeAddressString(address)
        guard let location = placemarks.first?.location else { throw LocationError.geocodingFailed }
        return (location.coordinate.latitude, location.coordinate.longitude)
    }
    
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else { throw LocationError.reverseGeocodingFailed }
        var parts: [String] = []
        if let street = placemark.thoroughfare { parts.append(street) }
        if let subLocality = placemark.subLocality { parts.append(subLocality) }
        if let locality = placemark.locality { parts.append(locality) }
        return parts.joined(separator: ", ")
    }
    
    private func updateAuthorizationStatus() {
        _authorizationStatus = switch locationManager.authorizationStatus {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorizedWhenInUse: .authorizedWhenInUse
        case .authorizedAlways: .authorizedAlways
        @unknown default: .notDetermined
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last { _currentLocation = (location.coordinate.latitude, location.coordinate.longitude) }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { updateAuthorizationStatus() }
}

enum LocationError: LocalizedError {
    case geocodingFailed, reverseGeocodingFailed, permissionDenied
    var errorDescription: String? {
        switch self {
        case .geocodingFailed: return "Could not find address"
        case .reverseGeocodingFailed: return "Could not determine address"
        case .permissionDenied: return "Location permission denied"
        }
    }
}

// MARK: - Other Services

final class NotificationService: NotificationServiceProtocol, @unchecked Sendable {
    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }
    func scheduleOrderReady(orderId: String, message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Order Ready!"
        content.body = message
        content.sound = .default
        let request = UNNotificationRequest(identifier: "order-ready-\(orderId)", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
    func scheduleDeliveryUpdate(orderId: String, status: DeliveryTrackingStatus) async {
        let content = UNMutableNotificationContent()
        content.title = "Delivery Update"
        content.body = status.displayName
        content.sound = .default
        let request = UNNotificationRequest(identifier: "delivery-\(orderId)", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
    func cancelNotification(id: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

final class AnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    func trackEvent(_ name: String, properties: [String: Any]?) async {
        #if DEBUG
        debugLog("[Analytics] \(name): \(properties ?? [:])")
        #endif
    }
    func trackScreen(_ name: String) async {
        #if DEBUG
        debugLog("[Analytics] Screen: \(name)")
        #endif
    }
    func setUserProperty(_ name: String, value: String?) async {}
    func trackPurchase(orderId: String, amount: Double, items: [OrderItem]) async {
        #if DEBUG
        debugLog("[Analytics] Purchase: \(orderId) - \(amount)")
        #endif
    }
}



final class HapticService: HapticServiceProtocol, @unchecked Sendable {
    func impact(_ style: HapticStyle) async {
        await MainActor.run {
            let generator: UIImpactFeedbackGenerator = switch style {
            case .light: UIImpactFeedbackGenerator(style: .light)
            case .medium: UIImpactFeedbackGenerator(style: .medium)
            case .heavy: UIImpactFeedbackGenerator(style: .heavy)
            case .soft: UIImpactFeedbackGenerator(style: .soft)
            case .rigid: UIImpactFeedbackGenerator(style: .rigid)
            }
            generator.impactOccurred()
        }
    }
    func notification(_ type: HapticNotificationType) async {
        await MainActor.run {
            let generator = UINotificationFeedbackGenerator()
            switch type {
            case .success: generator.notificationOccurred(.success)
            case .warning: generator.notificationOccurred(.warning)
            case .error: generator.notificationOccurred(.error)
            }
        }
    }
    func selection() async { await MainActor.run { UISelectionFeedbackGenerator().selectionChanged() } }
}

final class PresenceService: PresenceServiceProtocol, @unchecked Sendable {
    private let webSocketURL: URL
    private let authProvider: @Sendable () async -> String?
    private var webSocketTask: URLSessionWebSocketTask?
    private var _isConnected = false
    
    var isConnected: Bool { get async { _isConnected } }
    
    init(webSocketURL: URL, authProvider: @escaping @Sendable () async -> String?) {
        self.webSocketURL = webSocketURL
        self.authProvider = authProvider
    }
    
    func connect(storeId: String) async throws {
        guard let token = await authProvider() else { throw PresenceError.notAuthenticated }
        var request = URLRequest(url: webSocketURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        _isConnected = true
    }
    
    func disconnect() async {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        _isConnected = false
    }
    
    func checkIn(status: PresenceStatus, mode: PresenceMode) async throws {}
    func checkOut() async throws {}
    func updateStatus(_ status: PresenceStatus) async throws {}
}

enum PresenceError: LocalizedError {
    case notAuthenticated, encodingFailed, connectionFailed
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not authenticated"
        case .encodingFailed: return "Failed to encode message"
        case .connectionFailed: return "Connection failed"
        }
    }
}
