import Foundation

protocol AuthRepositoryProtocol: Sendable {
    func hasSession() async -> Bool
    func sendOTP(to phone: String) async throws
    func verifyOTP(phone: String, code: String) async throws
    func updateName(_ name: String) async throws
    func signOut() async
    func deleteAccount(phone: String, otp: String) async throws
}

protocol LoyaltyRepositoryProtocol: Sendable {
    func memberSnapshot(cursor: String?) async throws -> (Member, HistoryPage)
    func cachedSnapshot() async -> (Member, HistoryPage)?
    func memberQR() async throws -> MemberQR
    func clearCache() async
}
