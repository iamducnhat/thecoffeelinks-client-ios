import Foundation

/// Saved delivery address model
struct Address: Codable, Identifiable, Hashable {
    let id: String
    let address: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case address
        case createdAt = "created_at"
    }
    
    init(id: String, address: String, createdAt: Date? = nil) {
        self.id = id
        self.address = address
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Robust ID decoding (String or UUID)
        if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = String(idInt)
        } else {
            throw DecodingError.typeMismatch(String.self, DecodingError.Context(
                codingPath: container.codingPath + [CodingKeys.id],
                debugDescription: "Expected String or Int for Address ID"
            ))
        }
        
        self.address = try container.decode(String.self, forKey: .address)
        
        // Handle both ISO8601 string and timestamp
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            self.createdAt = formatter.date(from: dateString)
        } else {
            self.createdAt = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(address, forKey: .address)
        if let createdAt = createdAt {
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Address, rhs: Address) -> Bool {
        lhs.id == rhs.id
    }
}

/// Response wrapper for addresses API
struct AddressesResponse: Codable {
    let success: Bool
    let addresses: [Address]
}

/// Response wrapper for single address API
struct AddressResponse: Codable {
    let success: Bool
    let address: Address
    let alreadyExists: Bool?
}
