//
//  SearchView.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI

struct SearchView: View {
    // Mode 1: Driven by external native search bar (iOS 26+)
    var externalQuery: String = ""
    
    // Mode 2: Self-contained with internal Header (Legacy)
    var enableInternalSearch: Bool = false
    
    @StateObject private var viewModel = SearchViewModel()
    @State private var internalQuery: String = ""
    @Environment(\.dismiss) var dismiss
    
    init(externalQuery: String = "", enableInternalSearch: Bool = false) {
        self.externalQuery = externalQuery
        self.enableInternalSearch = enableInternalSearch
    }
    
    var activeQuery: String {
        enableInternalSearch ? internalQuery : externalQuery
    }
    
    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Internal Header for Legacy Mode
                if enableInternalSearch {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.secondary)
                        
                        TextField("Search coffee, food...", text: $internalQuery)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                Task { await viewModel.search() }
                            }
                            .onChange(of: internalQuery) { newValue in
                                viewModel.query = newValue
                            }
                        
                        if !internalQuery.isEmpty {
                            Button {
                                internalQuery = ""
                                viewModel.query = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                        
                        Button("Close") {
                            dismiss()
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding()
                }
                
                // CATEGORY FILTER CHIPS
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(["All", "Coffee", "Tea", "Food", "Merch"], id: \.self) { category in
                            Button {
                                viewModel.selectCategory(category)
                            } label: {
                                Text(category)
                                    .font(.brandSans(14))
                                    .fontWeight(viewModel.selectedCategory == category ? .bold : .medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(viewModel.selectedCategory == category ? Color.brandPrimary : Color.white)
                                    .foregroundStyle(viewModel.selectedCategory == category ? Color.white : Color.coffeeDark)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.coffeeRich.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                // MAIN CONTENT (Results or Full Menu)
                if viewModel.isLoading {
                    skeletonView
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Text("Unable to load menu")
                        Text(error).font(.caption).foregroundStyle(.red)
                        Button("Retry") { Task { await viewModel.search() } }
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        if !enableInternalSearch {
                            header
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.filteredProducts) { product in
                                ProductCard(product: product)
                            }
                        }
                        .padding()
                        
                        if viewModel.filteredProducts.isEmpty {
                            Text("No products found")
                                .foregroundStyle(.secondary)
                                .padding(.top, 40)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: externalQuery) { newValue in
            if !enableInternalSearch {
                viewModel.query = newValue
            }
        }
        .onAppear {
            // Load initial menu data
            Task { await viewModel.search() }
            if !enableInternalSearch {
                viewModel.query = externalQuery
            }
    }
    }

    // MARK: - Components
    
    private var header: some View {
        HStack {
            Text("Menu")
                .font(.brandSerif(32))
                .foregroundStyle(Color.brandPrimary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var skeletonView: some View {
        VStack(spacing: 20) {
            header
            
            // Filter Chips Skeleton
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4) { _ in
                        Capsule()
                            .fill(Color.coffeeRich.opacity(0.1))
                            .frame(width: 80, height: 32)
                    }
                }
                .padding(.horizontal)
            }
            
            // Grid Skeleton
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<6) { _ in
                    ProductCard(product: .placeholder, width: 160)
                }
            }
            .padding()
            
            Spacer()
        }
        .redacted(reason: .placeholder)
    }
}

struct SearchMenuCard: View {
    let title: String
    let image: String
    let color: Color
    
    var body: some View {
        VStack {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(color)
                }
            
            Text(title)
                .font(.brandSans(16))
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ProductRow: View {
    let product: Product
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: product.displayImageUrl ?? "")) { img in
                img.resizable()
                   .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.coffeeRich.opacity(0.1)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.brandSerif(16))
                    .foregroundStyle(Color.coffeeDark)
                
                Text(product.description ?? "")
                    .font(.brandSans(12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                Text("$\(String(format: "%.0f", product.price))")
                    .font(.brandSans(14))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.brandAccent)
            }
            
            Spacer()
            
            Image("chevron_right")
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundStyle(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    SearchView(enableInternalSearch: true)
}
