import Foundation
import Combine

@MainActor
class EventsViewModel: ObservableObject {
    @Published var viewState: ViewState = .idle
    @Published var events: [Event] = []
    
    private let eventService = EventService()
    
    func fetchEvents() async {
        self.viewState = .loading
        do {
            let fetchedEvents = try await eventService.getEvents()
            self.events = fetchedEvents
            
            if events.isEmpty {
                self.viewState = .empty
            } else {
                self.viewState = .loaded
            }
        } catch {
            self.viewState = .error(error.localizedDescription)
        }
    }
}
