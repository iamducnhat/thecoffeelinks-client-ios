import Foundation

actor LoyaltyRepository: LoyaltyRepositoryProtocol {
    private let client: APIClient
    private let cache: LiteCache

    init(client: APIClient, cache: LiteCache = LiteCache()) {
        self.client = client
        self.cache = cache
    }

    func memberSnapshot(cursor: String?) async throws -> (Member, HistoryPage) {
        var components = URLComponents()
        components.path = "/api/loyalty/me"
        components.queryItems = [URLQueryItem(name: "limit", value: "20")]
        if let cursor { components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor)) }
        let response: LoyaltyEnvelope = try await client.send(components.string ?? "/api/loyalty/me")
        if cursor == nil { await cache.save(member: response.member, history: response.history) }
        return (response.member, response.history)
    }

    func cachedSnapshot() async -> (Member, HistoryPage)? {
        guard let snapshot = await cache.load() else { return nil }
        return (snapshot.member, snapshot.history)
    }

    func memberQR() async throws -> MemberQR {
        let response: QREnvelope = try await client.send(
            "/api/loyalty/member-qr",
            method: .post,
            body: EmptyRequest(),
            attest: true
        )
        return response.qr
    }
}

private struct EmptyRequest: Encodable {}
private struct LoyaltyEnvelope: Decodable {
    let member: Member
    let history: HistoryPage
}
private struct QREnvelope: Decodable { let qr: MemberQR }
