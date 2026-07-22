import Foundation

struct PointTransaction: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let points: Int
    let kind: String
    let createdAt: Date
    let storeName: String?
    let invoiceCode: String?
    let eligibleAmount: Int?
    let vndPerPoint: Int?
    let description: String?

    var isCredit: Bool { points >= 0 }
}

struct HistoryPage: Codable, Equatable, Sendable {
    let items: [PointTransaction]
    let nextCursor: String?
}
