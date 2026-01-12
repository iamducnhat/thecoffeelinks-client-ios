import Foundation

enum Size: String, Codable {
    case S, M, L
}

struct Customization: Codable {
    let size: Size
    let sugarLevel: Int
    let iceLevel: Int
    let toppings: [String]
}

struct CartItem: Codable, Identifiable {
    let id: String
    let product: Product
    let customization: Customization
    let quantity: Int
}
