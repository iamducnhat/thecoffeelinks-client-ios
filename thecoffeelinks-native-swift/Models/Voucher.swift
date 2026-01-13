import Foundation

/// Voucher model - APIClient uses .convertFromSnakeCase
struct Voucher: Decodable, Identifiable {
    let _id: String?
    let code: String
    let type: String? // e.g., "discount", "free_item"
    let value: Double? // Amount or percentage
    let description: String?
    let minSpend: Double?
    let expiresAt: Date?
    let isUsed: Bool?
    let imageUrl: String? // Added for voucher images
    
    var id: String {
        _id ?? code
    }
    
    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case code
        case type
        case value
        case description
        case minSpend
        case expiresAt
        case isUsed
        case imageUrl
    }
}
