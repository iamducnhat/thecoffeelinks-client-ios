import Foundation

actor AuthRepository: AuthRepositoryProtocol {
    private let client: APIClient

    init(client: APIClient) { self.client = client }

    func hasSession() async -> Bool { await client.hasSession }

    func sendOTP(to phone: String) async throws {
        let _: BasicResponse = try await client.send(
            "/api/auth/otp/send",
            method: .post,
            body: PhoneRequest(phone: phone),
            authenticated: false
        )
    }

    func verifyOTP(phone: String, code: String) async throws {
        let response: SessionEnvelope = try await client.send(
            "/api/auth/otp/verify",
            method: .post,
            body: VerifyRequest(phone: phone, otp: code, type: "sms"),
            authenticated: false
        )
        try await client.beginAuthenticatedSession(response.session.authSession)
    }

    func updateName(_ name: String) async throws {
        let _: BasicResponse = try await client.send(
            "/api/user/profile",
            method: .put,
            body: NameRequest(name: name)
        )
    }

    func signOut() async { await client.clearSession() }

    func deleteAccount(phone: String, otp: String) async throws {
        let _: BasicResponse = try await client.send(
            "/api/user/account",
            method: .delete,
            body: DeleteAccountRequest(phone: phone, otp: otp),
            attest: true
        )
        await client.clearSession()
    }
}

private struct PhoneRequest: Encodable { let phone: String }
private struct VerifyRequest: Encodable { let phone: String; let otp: String; let type: String }
private struct NameRequest: Encodable { let name: String }
private struct DeleteAccountRequest: Encodable { let phone: String; let otp: String }
struct BasicResponse: Decodable { let success: Bool }
