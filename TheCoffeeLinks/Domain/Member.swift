import Foundation

struct Member: Codable, Equatable, Sendable {
    let id: String
    var fullName: String
    let phone: String
    let memberCode: String
    let points: Int
    let memberSince: Date
    let tier: String?

    var needsName: Bool {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || fullName == "User"
    }

    var maskedPhone: String {
        let digits = phone.filter(\.isNumber)
        guard digits.count >= 7 else { return phone }
        return "•••• ••• " + digits.suffix(3)
    }
}
