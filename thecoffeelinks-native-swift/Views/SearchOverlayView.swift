//
//  SearchOverlayView.swift
//  thecoffeelinks-native-swift
//
//  Full-screen Search Overlay per Blueprint H-002
//

import SwiftUI

struct SearchOverlayView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    @StateObject private var viewModel = SearchViewModel()
    
    // Local state for features not in SearchViewModel
    @State private var recentSearches: [String] = ["Bạc Xỉu", "Latte", "Trà Đào"]
    private let trending = ["Cà phê", "Trà sữa", "Bánh mì", "Croissant"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                if searchText.isEmpty {
                    // Empty State - Recent & Trending
                    emptyState
                } else {
                    // Search Results
                    searchResults
                }
            }
            .background(Color.morningFog)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) { isPresented = false } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .foregroundStyle(Color.forestCanopy)
                    }
                }
            }
        }
        .onAppear {
            isFocused = true
            Task {
                await viewModel.search()
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.neutral500)
            
            TextField("Search products, stores...", text: $searchText)
                .focused($isFocused)
                .font(.body)
                .foregroundStyle(Color.forestCanopy)
                .submitLabel(.search)
                .onChange(of: searchText) { newValue in
                    viewModel.query = newValue
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.neutral400)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recent Searches
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent")
                                .font(.headline)
                                .foregroundStyle(Color.forestCanopy)
                            Spacer()
                            Button("Clear") {
                                recentSearches.removeAll()
                            }
                            .font(.caption)
                            .foregroundStyle(Color.neutral500)
                        }
                        
                        ForEach(recentSearches, id: \.self) { search in
                            Button {
                                searchText = search
                                viewModel.query = search
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundStyle(Color.neutral400)
                                    Text(search)
                                        .foregroundStyle(Color.forestCanopy)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Trending
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trending")
                        .font(.headline)
                        .foregroundStyle(Color.forestCanopy)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(trending, id: \.self) { term in
                                Button {
                                    searchText = term
                                    viewModel.query = term
                                } label: {
                                    Text(term)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.forestCanopy)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.white)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories")
                        .font(.headline)
                        .foregroundStyle(Color.forestCanopy)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(viewModel.categories, id: \.id) { category in
                            Button {
                                viewModel.selectCategory(category)
                            } label: {
                                HStack {
                                    Text(category.name)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.forestCanopy)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Color.neutral400)
                                }
                                .padding(14)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }
    
    // MARK: - Search Results
    
    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.filteredProducts.isEmpty {
                    // No results
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.neutral300)
                        
                        Text("No results for \"\(searchText)\"")
                            .font(.headline)
                            .foregroundStyle(Color.forestCanopy)
                        
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundStyle(Color.neutral500)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(viewModel.filteredProducts) { product in
                        NavigationLink {
                            OrderCustomizationView(product: product)
                        } label: {
                            searchResultRow(product)
                        }
                        
                        Divider().padding(.leading, 88)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal)
            .padding(.top)
        }
    }
    
    private func searchResultRow(_ product: Product) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: product.displayImageUrl ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.neutral100)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.forestCanopy)
                
                if let category = product.category {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(Color.neutral500)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.neutral400)
        }
        .padding(12)
    }
}

// MARK: - Preview

#Preview {
    SearchOverlayView(isPresented: .constant(true))
}
