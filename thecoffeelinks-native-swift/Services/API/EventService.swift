import Foundation

// MARK: - API Response Wrappers

struct EventsResponse: Codable {
    let events: [Event]?
    let data: [Event]?
    let error: String?
    
    var items: [Event] {
        events ?? data ?? []
    }
}

// MARK: - EventService

class EventService: EventServiceProtocol {
    private let apiClient = APIClient.shared
    
    func getEvents() async throws -> [Event] {
        let response: EventsResponse = try await apiClient.get("/api/events")
        return response.items
    }
}
