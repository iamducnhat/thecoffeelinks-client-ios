import Foundation
import Combine

@MainActor
class NetworkViewModel: ObservableObject {
    @Published var viewState: ViewState = .idle
    @Published var checkedInUsers: [CheckIn] = [] // Requires CheckIn struct from NetworkService
    @Published var isCheckedIn: Bool = false
    
    private let networkService = NetworkService()
    private let storeService = StoreService()
    
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
    
    func checkIn(location: String? = nil) async {
        self.viewState = .loading
        do {
            var locationId = location
            
            // If no specific location is provided or it's the default placeholder, fetch a valid store ID
            if locationId == nil || locationId == "Main Lounge" {
                let stores = try await storeService.getStores()
                if let firstStore = stores.first {
                    locationId = firstStore.id
                }
            }
            
            guard let finalLocationId = locationId else {
                throw NSError(domain: "NetworkViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "No valid store found for check-in"])
            }
            
            try await networkService.checkIn(locationId: finalLocationId)
            self.isCheckedIn = true
            await fetchCheckIns()
        } catch {
            print("Check-in failed: \(error.localizedDescription)")
            self.viewState = .error(error.localizedDescription)
        }
    }
}
