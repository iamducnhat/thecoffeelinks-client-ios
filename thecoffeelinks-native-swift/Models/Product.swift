import Foundation

enum ProductCategory: String, Codable, CaseIterable {
    case coffee
    case tea
    case smoothies
    case pastries
    case seasonal
}

/// Product model - API returns camelCase, so we use camelCase property names.
/// Needs to be Codable for CartItem persistence.
/// APIClient will need to use .useDefaultKeys when fetching products.
struct Product: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let basePrice: Double?
    let category: ProductCategory?
    let categoryId: String?
    let image: String?
    let imageUrl: String?
    let isPopular: Bool?
    let isNew: Bool?
    let isActive: Bool?
    let isAvailable: Bool?
    
    // Computed for compatibility
    var displayImageUrl: String? { image ?? imageUrl }
    var price: Double { basePrice ?? 0 }
}
