import Foundation
import Combine
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var selectedCategory: Category = Category.all
    @Published var categories: [Category] = [Category.all]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Cache
    @Published var allProducts: [Product] = []
    
    // Computed Results
    var filteredProducts: [Product] {
        let term = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Filter by Category
        let categoryFiltered: [Product]
        if selectedCategory.id == "all" {
            categoryFiltered = allProducts
        } else {
            categoryFiltered = allProducts.filter { product in
                // Check exact ID match first
                if let catId = product.categoryId {
                    return catId == selectedCategory.id
                }
                // Fallback to name match for legacy/unmigrated data
                if let catName = product.category {
                    return catName.caseInsensitiveCompare(selectedCategory.name) == .orderedSame
                }
                return false
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
        // Fetch products and categories
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            async let productsTask = productService.getProducts()
            async let categoriesTask = productService.getCategories()
            
            let (fetchedProducts, fetchedCategories) = try await (productsTask, categoriesTask)
            
            self.allProducts = fetchedProducts
            self.categories = [Category.all] + fetchedCategories
            
        } catch {
            self.errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("Search error: \(error)")
        }
        
        self.isLoading = false
    }
    
    // Alias for simpler UI usage
    func selectCategory(_ category: Category) {
        self.selectedCategory = category
    }
}
