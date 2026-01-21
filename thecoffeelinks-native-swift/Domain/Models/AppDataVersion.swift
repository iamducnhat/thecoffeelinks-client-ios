import Foundation

struct AppDataVersion: Codable, Sendable {
    let key: String
    let version: Int
}

struct AppDataVersionsResponse: Codable, Sendable {
    let versions: [String: Int]
}
