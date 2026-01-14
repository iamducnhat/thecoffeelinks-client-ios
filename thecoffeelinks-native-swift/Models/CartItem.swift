import Foundation

struct OrderCustomization: Codable, Hashable {
    let size: String
    let ice: String?
    let sugar: String?
    let toppings: [String]? // Topping IDs
    var selectedToppingDetails: [Topping]? // Topping details for display (not encoded)
    
    // Custom encoding/decoding to exclude selectedToppingDetails from serialization
    enum CodingKeys: String, CodingKey {
        case size
        case ice
        case sugar
        case toppings
    }
    
    init(size: String, ice: String?, sugar: String?, toppings: [String]?, selectedToppingDetails: [Topping]? = nil) {
        self.size = size
        self.ice = ice
        self.sugar = sugar
        self.toppings = toppings
        self.selectedToppingDetails = selectedToppingDetails
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        size = try container.decode(String.self, forKey: .size)
        ice = try container.decodeIfPresent(String.self, forKey: .ice)
        sugar = try container.decodeIfPresent(String.self, forKey: .sugar)
        toppings = try container.decodeIfPresent([String].self, forKey: .toppings)
        selectedToppingDetails = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(size, forKey: .size)
        try container.encodeIfPresent(ice, forKey: .ice)
        try container.encodeIfPresent(sugar, forKey: .sugar)
        try container.encodeIfPresent(toppings, forKey: .toppings)
    }
}

struct CartItem: Identifiable, Codable {
    let id: UUID
    let product: Product
    var quantity: Int
    var finalPrice: Double
    let customization: OrderCustomization
    
    // Computed property for display
    var toppingsString: String {
        if let details = customization.selectedToppingDetails {
            return details.map { $0.name }.joined(separator: ", ")
        }
        return customization.toppings?.joined(separator: ", ") ?? ""
    }
}
