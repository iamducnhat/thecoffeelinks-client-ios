import SwiftUI
import Combine

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let favoritesRepository: FavoritesRepositoryProtocol
    
    init(favoritesRepository: FavoritesRepositoryProtocol) {
        self.favoritesRepository = favoritesRepository
    }
    
    func load() async {
        isLoading = true
        error = nil
        do {
            favorites = try await favoritesRepository.getFavorites()
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    func removeFavorite(id: String) async {
        do {
            try await favoritesRepository.removeFavorite(id: id)
            favorites.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }
}
