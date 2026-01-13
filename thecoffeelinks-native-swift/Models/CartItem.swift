import Foundation

struct OrderCustomization: Codable, Hashable {
    let size: String
    let ice: String?
    let sugar: String?
    let toppings: [String]?
}

struct CartItem: Identifiable, Codable {
    let id: UUID
    let product: Product
    var quantity: Int
    var finalPrice: Double
    let customization: OrderCustomization
    
    // Computed property for display
    var toppingsString: String {
        customization.toppings?.joined(separator: ", ") ?? ""
    }
}
