import Foundation

/// Service for managing user's saved delivery addresses
actor AddressService {
    static let shared = AddressService()
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - Fetch Addresses
    
    /// Fetch all saved addresses for the current user
    func fetchAddresses() async throws -> [Address] {
        let response: AddressesResponse = try await apiClient.get(
            "/api/user/addresses",
            keyDecodingStrategy: .convertFromSnakeCase
        )
        return response.addresses
    }
    
    // MARK: - Save Address
    
    /// Save a new delivery address
    /// - Parameter address: The address string to save
    /// - Returns: The saved address with ID
    func saveAddress(_ address: String) async throws -> Address {
        struct SaveAddressRequest: Encodable {
            let address: String
        }
        
        let response: AddressResponse = try await apiClient.post(
            "/api/user/addresses",
            body: SaveAddressRequest(address: address),
            keyDecodingStrategy: .convertFromSnakeCase
        )
        
        return response.address
    }
    
    // MARK: - Delete Address
    
    /// Delete a saved address
    /// - Parameter addressId: The ID of the address to delete
    func deleteAddress(id addressId: String) async throws {
        struct SuccessResponse: Decodable {
            let success: Bool
        }
        
        let _: SuccessResponse = try await apiClient.delete(
            "/api/user/addresses?id=\(addressId)",
            keyDecodingStrategy: .convertFromSnakeCase
        )
    }
}
