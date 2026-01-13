import Foundation

struct MenuResponse: Decodable {
    let categories: [MenuCategory]
    let products: [Product]
    let toppings: [Topping]
    let sizes: [String: SizeModifier]
    let sugarOptions: [ConfigOption]
    let iceOptions: [ConfigOption]
}

struct MenuCategory: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
}

struct Topping: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let price: Double
    let isAvailable: Bool
}

struct SizeModifier: Decodable, Hashable {
    let price: Double
    let label: String
}

struct ConfigOption: Decodable, Hashable {
    let value: String
    let label: String
}

// Extension to Product to ensure it matches API fields if needed
// Assuming Product currently exists, we might need to make sure decoding keys match.
// Existing Product struct is simplistic. We rely on JSONDecoder keyDecodingStrategy = .convertFromSnakeCase
