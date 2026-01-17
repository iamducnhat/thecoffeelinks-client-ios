//
//  DeliveryRepository.swift
//  thecoffeelinks-native-swift
//

import Foundation

// MARK: - Request Types

private struct SetDefaultRequest: Codable, Sendable { let isDefault: Bool }

// MARK: - Repository

final class DeliveryRepository: DeliveryRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func getAddresses() async throws -> [DeliveryAddress] {
        let response: AddressesResponse = try await networkService.get("/api/delivery/addresses", queryItems: nil)
        return response.addresses
    }
    
    func saveAddress(_ address: DeliveryAddress) async throws -> DeliveryAddress {
        let response: SaveAddressResponse = try await networkService.post("/api/delivery/addresses", body: address)
        return response.address
    }
    
    func updateAddress(_ address: DeliveryAddress) async throws -> DeliveryAddress {
        // Server expects ID in body for PUT /api/delivery/addresses
        // Assuming DeliveryAddress struct has 'id' and conforms to Encodable
        let response: SaveAddressResponse = try await networkService.put("/api/delivery/addresses", body: address)
        return response.address
    }
    
    func deleteAddress(id: String) async throws {
        // Server expects ID in query for DELETE /api/delivery/addresses
        try await networkService.delete("/api/delivery/addresses", queryItems: [URLQueryItem(name: "id", value: id)])
    }
    
    func setDefaultAddress(id: String) async throws {
        // Server doesn't have specific default endpoint. Use Generic Update.
        // Needs to send body with ID and isDefault=true
        struct SetDefaultBody: Encodable { let id: String; let isDefault: Bool; enum CodingKeys: String, CodingKey { case id; case isDefault = "is_default" } }
        let _: SaveAddressResponse = try await networkService.put("/api/delivery/addresses", body: SetDefaultBody(id: id, isDefault: true))
    }
    
    func checkAvailability(addressId: String?, latitude: Double?, longitude: Double?, storeId: String) async throws -> DeliveryAvailability {
        var queryItems = [URLQueryItem(name: "storeId", value: storeId)]
        if let addressId = addressId { queryItems.append(URLQueryItem(name: "addressId", value: addressId)) }
        else if let lat = latitude, let lon = longitude {
            queryItems.append(URLQueryItem(name: "latitude", value: String(lat)))
            queryItems.append(URLQueryItem(name: "longitude", value: String(lon)))
        }
        let response: DeliveryAvailabilityResponse = try await networkService.get("/api/delivery/availability", queryItems: queryItems)
        return response.availability
    }
    
    func getDeliveryZones(storeId: String) async throws -> [DeliveryZone] {
        // SERVER MISSING ENDPOINT /api/delivery/zones
        return []
    }
    
    func getDeliveryTracking(orderId: String) async throws -> DeliveryTracking {
        // SERVER MISSING ENDPOINT /api/delivery/tracking
        throw DeliveryError.unavailable("Tracking not supported")
    }
}

enum DeliveryError: LocalizedError {
    case addressNotFound, notInZone, unavailable(String)
    var errorDescription: String? {
        switch self {
        case .addressNotFound: return "Address not found"
        case .notInZone: return "Address is outside delivery zone"
        case .unavailable(let reason): return reason
        }
    }
}
