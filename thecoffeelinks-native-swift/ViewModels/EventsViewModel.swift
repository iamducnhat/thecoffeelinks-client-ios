import Foundation
import Combine

@MainActor
class EventsViewModel: ObservableObject {
    @Published var viewState: ViewState = .idle
    @Published var events: [Event] = []
    
    private let eventService = EventService()
    private let cacheKey = "events_cache"
    
    init() {
        if let cachedEvents = CacheManager.shared.load([Event].self, for: cacheKey) {
            self.events = cachedEvents
            self.viewState = .loaded
        }
    }
    
    func fetchEvents() async {
        // Only loading if not already populated from cache
        if events.isEmpty {
            self.viewState = .loading
        }
        
        do {
            let fetchedEvents = try await eventService.getEvents()
            self.events = fetchedEvents
            await CacheManager.shared.save(fetchedEvents, for: cacheKey)
            
            if events.isEmpty {
                self.viewState = .empty
            } else {
                self.viewState = .loaded
            }
        } catch {
            print("Error fetching events: \(error)")
            // Only set error state if we have no data
            if events.isEmpty {
                self.viewState = .error(error.localizedDescription)
            }
        }
    }
}
