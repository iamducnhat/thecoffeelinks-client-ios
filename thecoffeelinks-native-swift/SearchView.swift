//
//  SearchView.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI

struct SearchView: View {
    // Mode 1: Driven by external native search bar (iOS 26+)
    @Binding var externalQuery: String
    
    // Mode 2: Self-contained with internal Header (Legacy)
    var enableInternalSearch: Bool = false
    
    @StateObject private var viewModel = SearchViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    @State private var internalQuery: String = ""
    @Environment(\.dismiss) var dismiss
    
    init(externalQuery: Binding<String> = .constant(""), enableInternalSearch: Bool = false) {
        self._externalQuery = externalQuery
        self.enableInternalSearch = enableInternalSearch
    }
    
    var activeQuery: String {
        enableInternalSearch ? internalQuery : externalQuery
    }
    
    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MAIN HEADER
                header
                
                // INTERNAL SEARCH HEADER
                if enableInternalSearch {
                    VStack(spacing: 0) {
                        HStack {
                            Image("filter")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                .foregroundStyle(Color.secondary)
                            
                            TextField("Search coffee, food...", text: $internalQuery)
                                .textFieldStyle(.plain)
                                .font(.brandSans(16))
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
                                    Text("✕")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color.secondary.opacity(0.8))
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(10)
                        
                        Divider()
                            .padding(.top, 10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // CATEGORY FILTERS
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.categories, id: \.id) { category in
                            Button {
                                viewModel.selectCategory(category)
                            } label: {
                                Text(category.name)
                                    .font(.brandSans(14))
                                    .fontWeight(viewModel.selectedCategory.id == category.id ? .semibold : .regular)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(viewModel.selectedCategory.id == category.id ? Color.brandPrimary : Color.clear)
                                    .foregroundStyle(viewModel.selectedCategory.id == category.id ? Color.white : Color.primary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: viewModel.selectedCategory.id == category.id ? 0 : 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color.brandBackground)
                
                // SCROLLABLE CONTENT - Takes remaining space
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if let error = viewModel.errorMessage {
                        ScrollView {
                            VStack(spacing: 12) {
                                Image("bell")
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.secondary)
                                Text("Expected error")
                                    .font(.brandSerif(18))
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Retry") { Task { await viewModel.search() } }
                                    .buttonStyle(.bordered)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                    } else if viewModel.filteredProducts.isEmpty {
                        ScrollView {
                            VStack(spacing: 16) {
                                Image("filter")
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 48)
                                    .foregroundStyle(.secondary.opacity(0.5))
                                Text("No products found")
                                    .font(.brandSans(16))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.top, 60)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredProducts) { product in
                                    ProductRow(product: product)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: externalQuery) { newValue in
            if !enableInternalSearch {
                viewModel.query = newValue
            }
        }
        .onAppear {
            Task { await viewModel.search() }
            if !enableInternalSearch {
                viewModel.query = externalQuery
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        HStack {
            Text("Menu")
            .font(.brandSerif(32))
            .foregroundStyle(Color.brandPrimary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .padding(.top, 20)
    }
    
    
}

// Premium Product Card for Menu View
struct ProductRow: View {
    let product: Product
    @State private var showingCustomization = false
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Image with gradient overlay
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: product.displayImageUrl ?? "")) { img in
                    img.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Color.coffeeRich.opacity(0.05)
                        Image("coffee")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32)
                            .foregroundStyle(Color.coffeeRich.opacity(0.2))
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(width: 120, height: 120)
            .scaledToFit()
            
            // Details
            VStack(alignment: .leading, spacing: 6) {
                // Category Badge
                if let categoryName = product.category {
                    Text(categoryName.capitalized)
                        .font(.brandSans(10))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brandAccent)
                        .textCase(.uppercase)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brandAccent.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                // Product Name
                Text(product.name)
                    .font(.brandSerif(18))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.coffeeDark)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Description (if available)
                if let desc = product.description, !desc.isEmpty {
                    Text(desc)
                        .font(.brandSans(12))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Price - show medium price or first available
                if let sizeOptions = product.sizeOptions {
                    let displayPrice: Double? = {
                        if sizeOptions.medium.enabled {
                            return sizeOptions.medium.price
                        } else if sizeOptions.large.enabled {
                            return sizeOptions.large.price
                        } else if sizeOptions.small.enabled {
                            return sizeOptions.small.price
                        }
                        return nil
                    }()
                    
                    if let price = displayPrice {
                        Text(price.toVND())
                            .font(.brandSans(16))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.brandAccent)
                    }
                } else {
                    Text("Price varies")
                        .font(.brandSans(14))
                        .foregroundStyle(Color.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(24)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            showingCustomization = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .sheet(isPresented: $showingCustomization) {
            OrderCustomizationView(product: product)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    SearchView(enableInternalSearch: true)
}
