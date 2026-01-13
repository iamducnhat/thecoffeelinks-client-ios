import Foundation

/// Event model - matches server response format
/// Server returns: { id, type, title, subtitle, bg, icon }
struct Event: Codable, Identifiable {
    let id: String
    let type: String?
    let title: String
    let subtitle: String?
    let bg: String?
    let icon: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case subtitle
        case bg
        case icon
    }
    
    init(id: String, type: String?, title: String, subtitle: String?, bg: String?, icon: String?) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.bg = bg
        self.icon = icon
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
        self.bg = try container.decodeIfPresent(String.self, forKey: .bg)
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(bg, forKey: .bg)
        try container.encodeIfPresent(icon, forKey: .icon)
    }
}

