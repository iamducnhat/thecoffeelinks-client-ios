import Foundation
import Combine

@MainActor
class NetworkViewModel: ObservableObject {
    @Published var viewState: ViewState = .idle
    @Published var checkedInUsers: [CheckIn] = [] // Requires CheckIn struct from NetworkService
    @Published var isCheckedIn: Bool = false
    
    private let networkService = NetworkService()
    
    func fetchCheckIns() async {
        self.viewState = .loading
        do {
            let users = try await networkService.getCheckIns()
            self.checkedInUsers = users
            self.viewState = .loaded
        } catch {
            self.viewState = .error(error.localizedDescription)
        }
    }
    
    func checkIn(location: String = "Main Lounge") async {
        // Optimistic update or simple call
        do {
            try await networkService.checkIn(locationId: location)
            self.isCheckedIn = true // Should probably verify with server
            await fetchCheckIns()
        } catch {
            print("Check-in failed: \(error.localizedDescription)")
        }
    }
}
