import Foundation

enum ProductCategory: String, Codable, CaseIterable {
    case coffee
    case tea
    case smoothies
    case pastries
    case seasonal
}

struct Product: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let basePrice: Double
    let category: ProductCategory?
    let categoryId: String?
    let imageUrl: String?
    let isPopular: Bool?
    let isNew: Bool?
    let isActive: Bool?
    let isAvailable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category
        case basePrice = "base_price"
        case categoryId = "category_id"
        case imageUrl = "image_url"
        case isPopular = "is_popular"
        case isNew = "is_new"
        case isActive = "is_active"
        case isAvailable = "is_available"
    }
}

