import Foundation

struct Category: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    
    // For "All" category placeholder
    static let all = Category(id: "all", name: "All", type: "all")
}

struct CategoriesResponse: Decodable {
    let categories: [Category]?
    let error: String?
}
