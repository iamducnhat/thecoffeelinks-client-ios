import Foundation

// MARK: - API Response Wrappers

struct CheckInsResponse: Codable {
    let checkIns: [CheckIn]?
    let users: [CheckIn]?
    let data: [CheckIn]?
    let error: String?
    
    var items: [CheckIn] {
        checkIns ?? users ?? data ?? []
    }
}

struct CheckInResult: Codable {
    let success: Bool
    let checkIn: CheckIn?
    let error: String?
}

// MARK: - CheckIn Model

struct CheckIn: Codable, Identifiable {
    let id: String
    let userId: String?
    let locationId: String?
    let checkedInAt: String?
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case locationId = "location_id"
        case checkedInAt = "checked_in_at"
        case user
    }
}

// MARK: - NetworkService

class NetworkService: NetworkServiceProtocol {
    private let apiClient = APIClient.shared
    
    func getCheckIns() async throws -> [CheckIn] {
        let response: CheckInsResponse = try await apiClient.get("/api/social/connect")
        return response.items
    }
    
    func checkIn(locationId: String) async throws {
        struct CheckInRequest: Encodable {
            let locationId: String
        }
        
        let _: CheckInResult = try await apiClient.post("/api/social/connect", body: CheckInRequest(locationId: locationId))
    }
}
