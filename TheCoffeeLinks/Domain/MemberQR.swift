import Foundation

struct MemberQR: Codable, Equatable, Sendable {
    let payload: String
    let expiresAt: Date
    let memberCode: String

    func isExpired(at date: Date = Date()) -> Bool {
        expiresAt <= date
    }

    func secondsRemaining(at date: Date = Date()) -> Int {
        max(0, Int(expiresAt.timeIntervalSince(date)))
    }
}
