import Foundation

/// Event model - matches server response format
/// Server returns: { id, type, title, subtitle, description, date, storeId, hostName, bg, icon, imageURL }
struct Event: Codable, Identifiable {
    let id: String
    let type: String?
    let title: String
    let subtitle: String?
    let description: String?
    let date: Date?
    let storeId: String?
    let hostName: String?
    let bg: String?
    let icon: String?
    let imageURL: String?
    
    // Computed property for camelCase compatibility
    var imageUrl: String? { imageURL }
    
    /// Fetch the store location associated with this event
    /// Returns nil if storeId is not set or store cannot be found
    func fetchStore() async throws -> Store? {
        guard let storeId = storeId, !storeId.isEmpty else { return nil }
        
        let storeService = StoreService()
        let stores = try await storeService.getStores()
        return stores.first { $0.id == storeId }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case subtitle
        case description
        case date
        case storeId
        case hostName
        case bg
        case icon
        case imageURL
    }
    
    init(id: String, type: String?, title: String, subtitle: String?, description: String?, date: Date?, storeId: String?, hostName: String?, bg: String?, icon: String?, imageURL: String?) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.date = date
        self.storeId = storeId
        self.hostName = hostName
        self.bg = bg
        self.icon = icon
        self.imageURL = imageURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Robust ID decoding (String or Int)
        if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = String(idInt)
        } else {
            throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: container.codingPath + [CodingKeys.id], debugDescription: "Expected String or Int for Event ID"))
        }
        
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.title = try container.decode(String.self, forKey: .title)
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.storeId = try container.decodeIfPresent(String.self, forKey: .storeId)
        self.hostName = try container.decodeIfPresent(String.self, forKey: .hostName)
        self.bg = try container.decodeIfPresent(String.self, forKey: .bg)
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
        self.imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        
        // Decode date with ISO8601 format
        if let dateString = try? container.decode(String.self, forKey: .date) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.date = formatter.date(from: dateString)
        } else {
            self.date = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(storeId, forKey: .storeId)
        try container.encodeIfPresent(hostName, forKey: .hostName)
        try container.encodeIfPresent(bg, forKey: .bg)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        
        if let date = date {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: date), forKey: .date)
        }
    }
}

