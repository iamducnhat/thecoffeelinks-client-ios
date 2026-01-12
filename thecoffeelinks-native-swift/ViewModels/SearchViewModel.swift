import Foundation
import Combine
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var selectedCategory: String = "All"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Cache
    @Published var allProducts: [Product] = []
    
    // Computed Results
    var filteredProducts: [Product] {
        let term = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Filter by Category
        let categoryFiltered: [Product]
        if selectedCategory == "All" {
            categoryFiltered = allProducts
        } else {
            // Mapping UI Category names to API/Model values if needed
            // Assuming Product has a category field. If not, we might need logic.
            // Product struct has 'category'? Let me assume yes or use description/name heuristic if not.
            // Wait, Product model has 'category: String?'.
            categoryFiltered = allProducts.filter {
                guard let cat = $0.category?.rawValue else { return false }
                
                // Flexible matching
                if selectedCategory == "Food" {
                    return cat == "pastries" || cat == "food"
                }
                
                return cat.caseInsensitiveCompare(selectedCategory) == .orderedSame ||
                       cat.localizedCaseInsensitiveContains(selectedCategory)
            }
        }
        
        // 2. Filter by Query
        if term.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { product in
                product.name.lowercased().contains(term) ||
                (product.description?.lowercased().contains(term) ?? false)
            }
        }
    }
    
    private let productService = ProductService()
    
    func search() async {
        // Just ensure data is loaded. filtering happens efficiently in computed var or view.
        if allProducts.isEmpty {
            self.isLoading = true
            self.errorMessage = nil
            do {
                self.allProducts = try await productService.getProducts()
            } catch {
                self.errorMessage = "Failed to load menu: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
    
    // Alias for simpler UI usage
    func selectCategory(_ category: String) {
        self.selectedCategory = category
    }
}
