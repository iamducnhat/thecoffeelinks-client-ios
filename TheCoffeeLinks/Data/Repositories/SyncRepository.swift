import Foundation

protocol SyncRepositoryProtocol: Sendable {
    func getVersions() async throws -> [String: Int]
}

final class SyncRepository: SyncRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func getVersions() async throws -> [String: Int] {
        let response: AppDataVersionsResponse = try await networkService.get("/api/sync/versions", queryItems: nil)
        return response.versions
    }
}
