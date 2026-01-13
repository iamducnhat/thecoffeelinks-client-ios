import Foundation

/// Event model
struct Event: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let date: Date?
    let imageUrl: String?
    let hostName: String?
    let location: String?
    let type: String?
    
    // Explicit keys to map JSON snake_case
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case date
        case imageUrl = "image_url"
        case hostName = "host_name"
        case location
        case type
    }
    
    init(id: String, title: String, description: String?, date: Date?, imageUrl: String?, hostName: String?, location: String?, type: String?) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.imageUrl = imageUrl
        self.hostName = hostName
        self.location = location
        self.type = type
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
        
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.date = try container.decodeIfPresent(Date.self, forKey: .date)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.hostName = try container.decodeIfPresent(String.self, forKey: .hostName)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(hostName, forKey: .hostName)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(type, forKey: .type)
    }
}

