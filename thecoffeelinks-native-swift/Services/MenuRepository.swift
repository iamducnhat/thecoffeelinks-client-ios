import Foundation
import Combine

class MenuRepository: ObservableObject {
    static let shared = MenuRepository()
    
    @Published var menu: MenuResponse?
    @Published var isLoading = false
    @Published var error: String?
    
    private let client = APIClient.shared
    private let cacheKey = "menu_cache"
    
    private init() {
        // Load initial state from cache if available
        if let cachedMenu = CacheManager.shared.load(MenuResponse.self, for: cacheKey) {
            self.menu = cachedMenu
        }
    }
    
    @MainActor
    func fetchMenu() async {
        // Only show loading if we don't have data yet
        if menu == nil {
            isLoading = true
        }
        error = nil
        
        do {
            let response: MenuResponse = try await client.get("api/menu")
            self.menu = response
            await CacheManager.shared.save(response, for: cacheKey)
        } catch {
            print("Menu fetch error: \(error)")
            self.error = error.localizedDescription
            
            // If we have no data and failed to fetch, try loading from cache one last time ?
            // No, we already loaded it in init.
        }
        
        isLoading = false
    }
}
