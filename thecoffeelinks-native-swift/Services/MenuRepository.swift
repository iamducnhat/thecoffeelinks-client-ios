import Foundation
import Combine

class MenuRepository: ObservableObject {
    static let shared = MenuRepository()
    
    @Published var menu: MenuResponse?
    @Published var isLoading = false
    @Published var error: String?
    
    private let client = APIClient.shared
    
    @MainActor
    func fetchMenu() async {
        isLoading = true
        error = nil
        
        do {
            let response: MenuResponse = try await client.get("api/menu")
            self.menu = response
        } catch {
            print("Menu fetch error: \(error)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}
