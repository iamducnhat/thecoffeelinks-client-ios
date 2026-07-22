import Foundation

struct AuthSession: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: TimeInterval?
}

enum HTTPMethod: String { case get = "GET", post = "POST", put = "PUT", delete = "DELETE" }

enum APIError: LocalizedError, Equatable {
    case invalidResponse
    case unauthorized
    case server(status: Int, message: String)
    case offline

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return String(localized: "error.invalid_response")
        case .unauthorized: return String(localized: "error.session_expired")
        case .server(_, let message): return message
        case .offline: return String(localized: "error.offline")
        }
    }
}

actor APIClient {
    private let baseURL: URL
    private let urlSession: URLSession
    private let keychain: KeychainStore
    private let attestation: AppAttestClient
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var session: AuthSession?
    private let sessionKey = "lite.auth.session"

    init(baseURL: URL, urlSession: URLSession = .shared, keychain: KeychainStore = KeychainStore()) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.keychain = keychain
        self.attestation = AppAttestClient(baseURL: baseURL, urlSession: urlSession, keychain: keychain)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(), debugDescription: "Invalid ISO-8601 date")
        }
        self.decoder = decoder
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
        if let data = keychain.data(for: sessionKey) {
            self.session = try? JSONDecoder().decode(AuthSession.self, from: data)
        }
    }

    var hasSession: Bool { session != nil }

    func setSession(_ session: AuthSession) throws {
        self.session = session
        try keychain.set(JSONEncoder().encode(session), for: sessionKey)
    }

    func clearSession() {
        session = nil
        keychain.remove(sessionKey)
    }

    func send<Response: Decodable, Body: Encodable>(
        _ path: String,
        method: HTTPMethod = .get,
        body: Body?,
        authenticated: Bool = true,
        attest: Bool = false
    ) async throws -> Response {
        let bodyData = try body.map(encoder.encode)
        let response: (Data, HTTPURLResponse)
        do {
            response = try await perform(path, method: method, body: bodyData, authenticated: authenticated, attest: attest)
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw APIError.offline
        }

        if response.1.statusCode == 401, authenticated, try await refreshSession() {
            let retried = try await perform(path, method: method, body: bodyData, authenticated: true, attest: attest)
            return try decode(retried.0, response: retried.1)
        }
        return try decode(response.0, response: response.1)
    }

    func send<Response: Decodable>(
        _ path: String,
        method: HTTPMethod = .get,
        authenticated: Bool = true,
        attest: Bool = false
    ) async throws -> Response {
        try await send(
            path,
            method: method,
            body: Optional<NoRequestBody>.none,
            authenticated: authenticated,
            attest: attest
        )
    }

    private func perform(_ path: String, method: HTTPMethod, body: Data?, authenticated: Bool, attest: Bool) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: path, relativeTo: baseURL) else { throw APIError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authenticated, let token = session?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if attest {
                let headers = try await attestation.headers(accessToken: token)
                headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            }
        }
        let (data, rawResponse) = try await urlSession.data(for: request)
        guard let response = rawResponse as? HTTPURLResponse else { throw APIError.invalidResponse }
        return (data, response)
    }

    private func decode<Response: Decodable>(_ data: Data, response: HTTPURLResponse) throws -> Response {
        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 401 { throw APIError.unauthorized }
            let message = (try? decoder.decode(ErrorEnvelope.self, from: data).message) ?? HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
            throw APIError.server(status: response.statusCode, message: message)
        }
        if Response.self == EmptyResponse.self, data.isEmpty {
            return EmptyResponse() as! Response
        }
        do { return try decoder.decode(Response.self, from: data) }
        catch { throw APIError.invalidResponse }
    }

    private func refreshSession() async throws -> Bool {
        guard let refreshToken = session?.refreshToken else { return false }
        let payload = try encoder.encode(RefreshRequest(refreshToken: refreshToken))
        let result = try await perform("/api/auth/refresh", method: .post, body: payload, authenticated: false, attest: false)
        guard (200..<300).contains(result.1.statusCode), let envelope = try? decoder.decode(SessionEnvelope.self, from: result.0) else {
            clearSession()
            return false
        }
        try setSession(envelope.session.authSession)
        return true
    }
}

struct EmptyResponse: Codable {}
private struct NoRequestBody: Encodable {}
private struct ErrorEnvelope: Decodable {
    let error: String?
    let details: String?
    var message: String { details ?? error ?? String(localized: "error.generic") }
}
struct RefreshRequest: Encodable { let refreshToken: String }
struct SessionPayload: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: TimeInterval?
    var authSession: AuthSession { AuthSession(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt) }
}
struct SessionEnvelope: Decodable { let session: SessionPayload }
