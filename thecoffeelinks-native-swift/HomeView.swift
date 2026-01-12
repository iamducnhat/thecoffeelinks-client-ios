//
//  HomeView.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var appState: AppState // Keep for greeting
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.brandBackground.ignoresSafeArea()
                
                switch viewModel.viewState {
                case .loading:
                    ProgressView()
                case .error(let message):
                    VStack {
                        Text("Failed to load")
                        Text(message).font(.caption).foregroundStyle(.red)
                        Button("Retry") { Task { await viewModel.fetchData() } }
                    }
                case .idle, .loaded, .empty:
                    ScrollView {
                        VStack(spacing: 24) {
                            // 1. Dynamic Greeting
                            headerSection
                            
                            // 2. Context Stack (Active Order)
                            if let order = viewModel.activeOrder {
                                ActiveOrderCard(order: order)
                            } else {
                                // idle fallback (Featured Product)
                                if let featured = viewModel.featuredProducts.first {
                                    FeaturedProductCard(product: featured)
                                } else {
                                    // Fallback if no data
                                    Text("Relax and enjoy.")
                                        .font(.brandSans(14))
                                        .foregroundStyle(Color.secondary)
                                        .padding()
                                }
                            }
                            
                            // 3. Menu Discovery (Horizontal)
                            menuDiscoverySection
                            
                            Spacer()
                        }
                        .padding(.top, 20)
                    }
                    .refreshable {
                        await viewModel.fetchData()
                    }
                }
            }
            .task {
                await viewModel.fetchData()
            }
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.brandSerif(28))
                    .foregroundStyle(Color.brandPrimary)
                
                Text("Ready for your coffee break?")
                    .font(.brandSans(14))
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            
            // Profile / Avatar Button
            Circle()
                .fill(Color.coffeeRich.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay {
                    Image("user")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.coffeeDark)
                }
        }
        .padding(.horizontal)
    }
    
    private var menuDiscoverySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Menu")
                .font(.brandSerif(20))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    MenuCategoryCard(title: "Coffee", image: "cup.and.saucer.fill", color: .coffeeRich)
                    MenuCategoryCard(title: "Food", image: "fork.knife", color: .brandAccent)
                    MenuCategoryCard(title: "Merch", image: "bag.fill", color: .brandPremium)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var greetingText: String {
        switch appState.timeMode {
        case .morning: return "Good Morning" // Simplified generic greeting if name not synced
        case .day: return "Good Afternoon"
        case .evening: return "Good Evening"
        }
    }
}

// MARK: - Subviews

struct ActiveOrderCard: View {
    let order: Order
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("ACTIVE ORDER")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.brandAccent)
                
                Text(order.status.rawValue.uppercased())
                    .font(.brandSerif(20))
                    .foregroundStyle(Color.white)
                
                Text("\(order.deliveryOption.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) • $\(String(format: "%.0f", order.total))")
                    .font(.brandSans(14))
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            Spacer()
            Image("arrow_right_circle")
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.white)
        }
        .padding()
        .background(Color.coffeeDark)
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.coffeeBlack.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct FeaturedProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FEATURED SEASONAL")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.brandPremium)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.brandSerif(22))
                    Text(product.description ?? "")
                        .font(.brandSans(14))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { img in
                    img.resizable()
                       .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.coffeeRich.opacity(0.1)
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MenuCategoryCard: View {
    let title: String
    let image: String // System Name
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
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
            
            Spacer()
            
            Text(title)
                .font(.brandSans(16))
                .fontWeight(.medium)
        }
        .padding()
        .frame(width: 140, height: 180)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
