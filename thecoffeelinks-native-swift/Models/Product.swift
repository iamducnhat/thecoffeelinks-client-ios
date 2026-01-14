import Foundation

enum ProductCategory: String, Codable, CaseIterable {
    case coffee
    case tea
    case smoothies
    case pastries
    case seasonal
}

struct SizeOption: Codable {
    let enabled: Bool
    let price: Double
}

struct ProductSizeOptions: Codable {
    let small: SizeOption
    let medium: SizeOption
    let large: SizeOption
}

/// Product model - API returns camelCase, so we use camelCase property names.
/// Needs to be Codable for CartItem persistence.
/// APIClient will need to use .useDefaultKeys when fetching products.
struct Product: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let category: String? // Changed to String to support dynamic categories
    let categoryId: String?
    let categoryType: String?
    let image: String?
    let imageUrl: String?
    let isPopular: Bool?
    let isNew: Bool?
    let isActive: Bool?
    let isAvailable: Bool?
    let sizeOptions: ProductSizeOptions?
    let availableToppings: [String]? // Array of topping IDs available for this product
    
    // Computed for compatibility
    var displayImageUrl: String? {
        let rawUrl = image ?? imageUrl
        guard let rawUrl = rawUrl, !rawUrl.isEmpty else { return nil }
        
        // If already a full URL, return as-is
        if rawUrl.hasPrefix("http://") || rawUrl.hasPrefix("https://") {
            return rawUrl
        }
        
        // If relative path, construct full URL
        // In production this should be dynamic, but keeping hardcoded server logic as per previous implementation
        if rawUrl.hasPrefix("/") {
            return "https://server-nu-three-90.vercel.app" + rawUrl
        }
        
        // Otherwise treat as relative and prepend slash
        return "https://server-nu-three-90.vercel.app/" + rawUrl
    }
    
    // Get available sizes with their prices
    var availableSizes: [(size: String, price: Double)] {
        guard let options = sizeOptions else { return [] }
        var sizes: [(String, Double)] = []
        if options.small.enabled { sizes.append(("Small", options.small.price)) }
        if options.medium.enabled { sizes.append(("Medium", options.medium.price)) }
        if options.large.enabled { sizes.append(("Large", options.large.price)) }
        return sizes
    }
}
