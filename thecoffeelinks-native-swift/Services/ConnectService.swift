//
//  ConnectService.swift
//  thecoffeelinks-native-swift
//
//  Backend integration for Connect/Networking features
//

import Foundation

// MARK: - Connect Service

class ConnectService {
    static let shared = ConnectService()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - Check-In / Check-Out
    
    func checkIn(storeId: String, status: PresenceStatus) async throws -> EnhancedCheckIn {
        struct Request: Encodable {
            let storeId: String
            let status: String
        }
        
        struct Response: Decodable {
            let checkIn: EnhancedCheckIn?
            let error: String?
        }
        
        let response: Response = try await apiClient.post(
            "/api/social/check-in",
            body: Request(storeId: storeId, status: status.rawValue)
        )
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
        
        guard let checkIn = response.checkIn else {
            throw ConnectError.invalidResponse
        }
        
        return checkIn
    }
    
    func checkOut() async throws {
        struct Response: Decodable {
            let success: Bool?
            let error: String?
        }
        
        let response: Response = try await apiClient.post("/api/social/check-out", body: EmptyBody())
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
    }
    
    func updatePresenceStatus(_ status: PresenceStatus) async throws {
        struct Request: Encodable {
            let status: String
        }
        
        struct Response: Decodable {
            let success: Bool?
            let error: String?
        }
        
        let response: Response = try await apiClient.patch(
            "/api/social/presence",
            body: Request(status: status.rawValue)
        )
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
    }
    
    // MARK: - Discovery
    
    func getDiscoverableUsers(storeId: String, limit: Int = 20) async throws -> [EnhancedCheckIn] {
        struct Response: Decodable {
            let users: [EnhancedCheckIn]?
            let data: [EnhancedCheckIn]?
            let error: String?
            
            var items: [EnhancedCheckIn] {
                users ?? data ?? []
            }
        }
        
        let response: Response = try await apiClient.get("/api/social/discover?storeId=\(storeId)&limit=\(limit)")
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
        
        return response.items
    }
    
    // MARK: - Connections (Digital Handshake)
    
    func sendConnectionRequest(toUserId: String, message: String? = nil) async throws -> ConnectionRequest {
        struct Request: Encodable {
            let toUserId: String
            let message: String?
        }
        
        struct Response: Decodable {
            let connection: ConnectionRequest?
            let error: String?
            let rateLimited: Bool?
            let retryAfter: Int?
        }
        
        let response: Response = try await apiClient.post(
            "/api/social/connections",
            body: Request(toUserId: toUserId, message: message)
        )
        
        if response.rateLimited == true {
            throw ConnectError.rateLimited(retryAfter: response.retryAfter ?? 3600)
        }
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
        
        guard let connection = response.connection else {
            throw ConnectError.invalidResponse
        }
        
        return connection
    }
    
    func respondToConnection(requestId: String, accept: Bool) async throws {
        struct Request: Encodable {
            let accept: Bool
        }
        
        struct Response: Decodable {
            let success: Bool?
            let error: String?
        }
        
        let response: Response = try await apiClient.patch(
            "/api/social/connections/\(requestId)",
            body: Request(accept: accept)
        )
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
    }
    
    func getConnectionRequests() async throws -> [ConnectionRequest] {
        struct Response: Decodable {
            let requests: [ConnectionRequest]?
            let data: [ConnectionRequest]?
            let error: String?
            
            var items: [ConnectionRequest] {
                requests ?? data ?? []
            }
        }
        
        let response: Response = try await apiClient.get("/api/social/connections/requests")
        return response.items
    }
    
    func getConnections() async throws -> [ConnectionRequest] {
        struct Response: Decodable {
            let connections: [ConnectionRequest]?
            let data: [ConnectionRequest]?
            let error: String?
            
            var items: [ConnectionRequest] {
                connections ?? data ?? []
            }
        }
        
        let response: Response = try await apiClient.get("/api/social/connections")
        return response.items
    }
    
    func getConnectionStatus(userId: String) async throws -> ConnectionStatus {
        struct Response: Decodable {
            let status: String?
            let error: String?
        }
        
        let response: Response = try await apiClient.get("/api/social/connections/status/\(userId)")
        
        if let statusStr = response.status, let status = ConnectionStatus(rawValue: statusStr) {
            return status
        }
        
        return .none
    }
    
    // MARK: - Coffee Treat
    
    func sendCoffeeTreat(toUserId: String, productId: String, message: String? = nil) async throws -> CoffeeTreat {
        struct Request: Encodable {
            let toUserId: String
            let productId: String
            let message: String?
        }
        
        struct Response: Decodable {
            let treat: CoffeeTreat?
            let error: String?
            let paymentRequired: Bool?
        }
        
        let response: Response = try await apiClient.post(
            "/api/social/coffee-treat",
            body: Request(toUserId: toUserId, productId: productId, message: message)
        )
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
        
        guard let treat = response.treat else {
            throw ConnectError.invalidResponse
        }
        
        return treat
    }
    
    func respondToCoffeeTreat(treatId: String, accept: Bool) async throws {
        struct Request: Encodable {
            let accept: Bool
        }
        
        struct Response: Decodable {
            let success: Bool?
            let error: String?
        }
        
        let response: Response = try await apiClient.patch(
            "/api/social/coffee-treat/\(treatId)",
            body: Request(accept: accept)
        )
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
    }
    
    func getPendingTreats() async throws -> [CoffeeTreat] {
        struct Response: Decodable {
            let treats: [CoffeeTreat]?
            let data: [CoffeeTreat]?
            let error: String?
            
            var items: [CoffeeTreat] {
                treats ?? data ?? []
            }
        }
        
        let response: Response = try await apiClient.get("/api/social/coffee-treat/pending")
        return response.items
    }
    
    // MARK: - Block / Report
    
    func blockUser(userId: String) async throws {
        struct Request: Encodable {
            let blockedUserId: String
        }
        
        struct Response: Decodable {
            let success: Bool?
            let error: String?
        }
        
        let response: Response = try await apiClient.post(
            "/api/social/block",
            body: Request(blockedUserId: userId)
        )
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
    }
    
    func unblockUser(userId: String) async throws {
        struct Response: Decodable {
            let success: Bool?
            let error: String?
        }
        
        let response: Response = try await apiClient.delete("/api/social/block/\(userId)")
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
    }
    
    func reportUser(userId: String, reason: ReportReason, details: String? = nil) async throws {
        struct Request: Encodable {
            let reportedUserId: String
            let reason: String
            let details: String?
        }
        
        struct Response: Decodable {
            let success: Bool?
            let error: String?
        }
        
        let response: Response = try await apiClient.post(
            "/api/social/report",
            body: Request(reportedUserId: userId, reason: reason.rawValue, details: details)
        )
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
    }
    
    func getBlockedUsers() async throws -> [String] {
        struct Response: Decodable {
            let blockedIds: [String]?
            let error: String?
        }
        
        let response: Response = try await apiClient.get("/api/social/block")
        return response.blockedIds ?? []
    }
    
    // MARK: - Business Card
    
    func getBusinessCard(userId: String) async throws -> DigitalBusinessCard {
        struct Response: Decodable {
            let card: DigitalBusinessCard?
            let error: String?
        }
        
        let response: Response = try await apiClient.get("/api/social/business-card/\(userId)")
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
        
        guard let card = response.card else {
            throw ConnectError.invalidResponse
        }
        
        return card
    }
    
    func updateBusinessCard(_ card: DigitalBusinessCard) async throws {
        struct Response: Decodable {
            let success: Bool?
            let error: String?
        }
        
        let response: Response = try await apiClient.patch("/api/social/business-card", body: card)
        
        if let error = response.error {
            throw ConnectError.serverError(error)
        }
    }
}

// MARK: - Errors

enum ConnectError: LocalizedError {
    case serverError(String)
    case invalidResponse
    case rateLimited(retryAfter: Int)
    case userNotFound
    case alreadyConnected
    case blockedUser
    case focusModeActive
    
    var errorDescription: String? {
        switch self {
        case .serverError(let msg): return msg
        case .invalidResponse: return "Invalid response from server"
        case .rateLimited(let seconds): return "Too many requests. Try again in \(seconds / 60) minutes."
        case .userNotFound: return "User not found"
        case .alreadyConnected: return "Already connected with this person"
        case .blockedUser: return "Cannot connect with blocked user"
        case .focusModeActive: return "This person is in Focus Mode"
        }
    }
}

// MARK: - Empty Body Helper

private struct EmptyBody: Encodable {}
