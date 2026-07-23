import CryptoKit
import DeviceCheck
import Foundation

actor AppAttestClient {
    private let baseURL: URL
    private let urlSession: URLSession
    private let keychain: KeychainStore
    private let service = DCAppAttestService.shared
    private let keyIDKey = "lite.app_attest.key_id"
    private let registeredKey = "lite.app_attest.registered"
    private let deviceIDKey = "lite.device_id"

    init(baseURL: URL, urlSession: URLSession, keychain: KeychainStore) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.keychain = keychain
    }

    func headers(accessToken: String) async throws -> [String: String] {
        guard service.isSupported else { return [:] }
        let keyID = try await ensureRegistered(accessToken: accessToken)
        let challenge = try await fetchChallenge(accessToken: accessToken)
        let assertion = try await service.generateAssertion(keyID, clientDataHash: Data(SHA256.hash(data: Data(challenge.utf8))))
        return [
            "X-App-Attest-Key-Id": keyID,
            "X-App-Attest-Assertion": assertion.base64EncodedString(),
            "X-App-Attest-Challenge": challenge
        ]
    }

    func resetRegistration() {
        // App Attest keys are bound to the authenticated member on the server.
        // Abandon the key on account changes; keep the stable device ID.
        keychain.remove(registeredKey)
        keychain.remove(keyIDKey)
    }

    private func ensureRegistered(accessToken: String) async throws -> String {
        let keyID: String
        if let data = keychain.data(for: keyIDKey), let saved = String(data: data, encoding: .utf8) {
            keyID = saved
        } else {
            keyID = try await service.generateKey()
            try keychain.set(Data(keyID.utf8), for: keyIDKey)
        }
        if keychain.data(for: registeredKey) != nil { return keyID }

        let challenge = try await fetchChallenge(accessToken: accessToken)
        let attestation = try await service.attestKey(keyID, clientDataHash: Data(SHA256.hash(data: Data(challenge.utf8))))
        let deviceID = try persistentDeviceID()
        let body = try JSONEncoder().encode(RegisterRequest(
            keyId: keyID,
            attestKey: attestation.base64EncodedString(),
            challenge: challenge,
            deviceId: deviceID
        ))
        let _: SuccessResponse = try await request(
            "/api/auth/app-attest/register",
            method: "POST",
            body: body,
            accessToken: accessToken
        )
        try keychain.set(Data([1]), for: registeredKey)
        return keyID
    }

    private func fetchChallenge(accessToken: String) async throws -> String {
        let response: ChallengeResponse = try await request(
            "/api/auth/app-attest/challenge",
            method: "GET",
            body: nil,
            accessToken: accessToken
        )
        return response.challenge
    }

    private func persistentDeviceID() throws -> String {
        if let data = keychain.data(for: deviceIDKey), let value = String(data: data, encoding: .utf8) { return value }
        let value = UUID().uuidString.lowercased()
        try keychain.set(Data(value.utf8), for: deviceIDKey)
        return value
    }

    private func request<Response: Decodable>(
        _ path: String,
        method: String,
        body: Data?,
        accessToken: String
    ) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else { throw APIError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await urlSession.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(response.statusCode) else {
            throw APIError.server(status: response.statusCode, message: String(localized: "error.attestation"))
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }
}

private struct RegisterRequest: Encodable {
    let keyId: String
    let attestKey: String
    let challenge: String
    let deviceId: String
}
private struct ChallengeResponse: Decodable { let challenge: String }
private struct SuccessResponse: Decodable { let success: Bool }
