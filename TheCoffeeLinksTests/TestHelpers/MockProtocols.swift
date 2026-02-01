//
//  MockProtocols.swift
//  TheCoffeeLinksTests
//
//  Mock protocols for dependency injection in tests
//

import Foundation
import Combine
@testable import TheCoffeeLinks

// MARK: - Networking Mocks

protocol MockableNetworkService {
    func request<T: Decodable>(_ endpoint: String, method: String, body: Encodable?, queryItems: [URLQueryItem]?) async throws -> T
    func setAuthSession(accessToken: String, refreshToken: String?)
    func clearAuthToken()
    var authToken: String? { get }
}

class MockNetworkService: MockableNetworkService {
    var authToken: String?
    var mockResponses: [String: Any] = [:]
    var shouldFail = false
    var failureError: Error = NetworkError.unknown
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil, queryItems: [URLQueryItem]? = nil) async throws -> T {
        if shouldFail {
            throw failureError
        }
        
        guard let response = mockResponses[endpoint] as? T else {
            throw NetworkError.noData
        }
        
        return response
    }
    
    func setAuthSession(accessToken: String, refreshToken: String? = nil) {
        self.authToken = accessToken
    }
    
    func clearAuthToken() {
        authToken = nil
    }
    
    func setMockResponse<T: Encodable>(for endpoint: String, response: T) {
        mockResponses[endpoint] = response
    }
}

// MARK: - Repository Mocks

class MockAuthRepository {
    var shouldFail = false
    var mockUser: User?
    
    func signIn(email: String, password: String) async throws -> User {
        if shouldFail {
            throw NetworkError.unauthorized
        }
        return mockUser ?? TestDataFactory.createUser()
    }
    
    func register(phone: String, password: String, name: String, dob: String) async throws -> Bool {
        if shouldFail {
            throw NetworkError.serverError("Registration failed")
        }
        return true
    }
    
    func verifyOTP(phone: String, otp: String) async throws -> User {
        if shouldFail {
            throw NetworkError.unauthorized
        }
        return mockUser ?? TestDataFactory.createUser()
    }
    
    func signOut() async throws {
        if shouldFail {
            throw NetworkError.unknown
        }
    }
    
    func getCurrentUser() async throws -> User {
        if shouldFail {
            throw NetworkError.unauthorized
        }
        return mockUser ?? TestDataFactory.createUser()
    }
}

class MockProductRepository {
    var shouldFail = false
    var mockProducts: [Product] = []
    var mockCategories: [ProductCategory] = []
    
    func fetchProducts() async throws -> [Product] {
        if shouldFail {
            throw NetworkError.networkFailure(URLError(.notConnectedToInternet))
        }
        return mockProducts.isEmpty ? TestDataFactory.createProducts() : mockProducts
    }
    
    func fetchCategories() async throws -> [ProductCategory] {
        if shouldFail {
            throw NetworkError.networkFailure(URLError(.notConnectedToInternet))
        }
        return mockCategories.isEmpty ? TestDataFactory.createCategories() : mockCategories
    }
    
    func searchProducts(query: String) async throws -> [Product] {
        if shouldFail {
            throw NetworkError.networkFailure(URLError(.notConnectedToInternet))
        }
        return mockProducts.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
}

class MockCartService {
    @Published var items: [CartItem] = []
    @Published var isLoading = false
    
    var total: Double {
        items.reduce(0) { $0 + ($1.product.basePrice * Double($1.quantity)) }
    }
    
    func addItem(product: Product, quantity: Int = 1, sizeOption: SizeOption? = nil, toppings: [Topping] = []) {
        if let existingIndex = items.firstIndex(where: { $0.product.id == product.id }) {
            items[existingIndex].quantity += quantity
        } else {
            let cartItem = CartItem(
                id: UUID().uuidString,
                product: product,
                quantity: quantity,
                selectedSize: sizeOption,
                selectedToppings: toppings
            )
            items.append(cartItem)
        }
    }
    
    func removeItem(itemId: String) {
        items.removeAll { $0.id == itemId }
    }
    
    func updateQuantity(itemId: String, quantity: Int) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            if quantity > 0 {
                items[index].quantity = quantity
            } else {
                items.remove(at: index)
            }
        }
    }
    
    func clearCart() {
        items.removeAll()
    }
}

class MockDeliveryService {
    @Published var selectedAddress: DeliveryAddress?
    @Published var estimatedETA: Int?
    @Published var deliveryFee: Double = 0
    @Published var isAvailable = true
    
    func validateAddress(_ address: DeliveryAddress) async throws -> Bool {
        return true
    }
    
    func calculateFee(for address: DeliveryAddress) async throws -> Double {
        return 25000
    }
    
    func estimateDeliveryTime(for address: DeliveryAddress) async throws -> Int {
        return 30
    }
}

// MARK: - Storage Mocks

class MockKeychainManager {
    private var storage: [String: String] = [:]
    
    func saveAccessToken(_ token: String) {
        storage["access_token"] = token
    }
    
    func getAccessToken() -> String? {
        return storage["access_token"]
    }
    
    func saveRefreshToken(_ token: String) {
        storage["refresh_token"] = token
    }
    
    func getRefreshToken() -> String? {
        return storage["refresh_token"]
    }
    
    func deleteAccessToken() {
        storage.removeValue(forKey: "access_token")
    }
    
    func deleteRefreshToken() {
        storage.removeValue(forKey: "refresh_token")
    }
    
    func clearAll() {
        storage.removeAll()
    }
}

class MockUserDefaults {
    private var storage: [String: Any] = [:]
    
    func set(_ value: Any?, forKey key: String) {
        storage[key] = value
    }
    
    func string(forKey key: String) -> String? {
        return storage[key] as? String
    }
    
    func bool(forKey key: String) -> Bool {
        return storage[key] as? Bool ?? false
    }
    
    func data(forKey key: String) -> Data? {
        return storage[key] as? Data
    }
    
    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}

// MARK: - Location Mock

class MockLocationManager {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    func requestPermission() {
        authorizationStatus = .authorizedWhenInUse
    }
    
    func startLocationUpdates() {
        // Mock Ho Chi Minh City location
        currentLocation = CLLocation(latitude: 10.762622, longitude: 106.660172)
    }
    
    func stopLocationUpdates() {
        currentLocation = nil
    }
}

// MARK: - Analytics Mock

class MockAnalyticsService {
    var trackedEvents: [(event: String, parameters: [String: Any])] = []
    
    func track(event: String, parameters: [String: Any] = [:]) {
        trackedEvents.append((event: event, parameters: parameters))
    }
    
    func clearTrackedEvents() {
        trackedEvents.removeAll()
    }
}