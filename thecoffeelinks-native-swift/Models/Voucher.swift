import Foundation

struct Voucher: Codable, Identifiable {
    let id: String
    let code: String
    let type: String // e.g., "discount", "free_item"
    let value: Double // Amount or percentage
    let description: String
    let minSpend: Double?
    let expiresAt: Date?
    let isUsed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, code, type, value, description
        case minSpend = "min_spend"
        case expiresAt = "expires_at"
        case isUsed = "is_used"
    }
}
