import Foundation

struct Event: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let date: Date // Handled by Supabase date decoding
    let imageUrl: String?
    let hostName: String?
    let location: String?
    let type: String? // "workshop", "tasting", "social"
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, date
        case imageUrl = "image_url"
        case hostName = "host_name"
        case location, type
    }
}
