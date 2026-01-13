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
    
    @Namespace private var namespace
    
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
                            // 1. Header (Greeting + Profile)
                            headerSection
                            
                            // 2. Active Order (if any, High Priority)
                            if let order = viewModel.activeOrder {
                                ActiveOrderCard(order: order)
                            }
                            
                            // 3. Highlights (Vouchers/Events)
                            if !viewModel.highlights.isEmpty {
                                highlightsSection
                            }
                            
                            // 4. Trending Products (IsPopular)
                            if !viewModel.trendingProducts.isEmpty {
                                sectionHeader(title: "Trending Now")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.trendingProducts) { product in
                                            ProductCard(product: product, width: 140)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // 5. Recent Ordered (History)
                            if !viewModel.recentProducts.isEmpty {
                                sectionHeader(title: "Order Again")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.recentProducts) { product in
                                            ProductCard(product: product, width: 140)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            Spacer().frame(height: 40)
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
                
                Text(appState.timeMode == .morning ? "Start your day right." : "Ready for your coffee break?")
                    .font(.brandSans(14))
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer()
            
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 12) {
                    HStack {
                        // Notification / Events Button
                        NavigationLink(destination: EventsView()) {
                            Image("bell")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color.brandPrimary)
                                .padding(12)
                                .contentShape(Circle())
                                .glassEffect(.clear.interactive())
                                .clipShape(Circle())
                                .glassEffectID("notifications", in: namespace)
                        }
                        // Profile / Avatar Button
                        NavigationLink(destination: ProfileView()) {
                            Image("user")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color.brandPrimary)
                                .padding(12)
                                .contentShape(Circle())
                                .glassEffect(.clear.interactive())
                                .clipShape(Circle())
                                .glassEffectID("profile", in: namespace)
                        }
                    }
                }
            } else {
                // Notification / Events Button
                NavigationLink(destination: EventsView()) {
                    Circle()
                        .fill(Color.coffeeRich.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image("bell")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color.brandAccent)
                        }
                }
                // Profile / Avatar Button
                NavigationLink(destination: ProfileView()) {
                    Circle()
                        .fill(Color.coffeeRich.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image("user")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color.coffeeDark)
                        }
                }
            }
        }
        .padding(.horizontal)
    }
    
    
    private var highlightCardHeight: CGFloat {
        let width = UIScreen.main.bounds.width - 32 // Horizontal padding
        return width / 2
    }
    
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Highlights")
            
            TabView {
                ForEach(viewModel.highlights) { item in
                    switch item {
                    case .voucher(let voucher):
                        HighlightCard(
                            title: voucher.code,
                            subtitle: "\(Int(voucher.value ?? 0))pts",
                            icon: "ticket",
                            color: .brandAccent
                        )
                        .padding(.horizontal) // Inner padding
                        .padding(.vertical, 20)
                    case .event(let event):
                        HighlightCard(
                            title: event.title,
                            subtitle: event.date?.formatted(.dateTime.weekday().day()) ?? "Upcoming",
                            icon: "calendar",
                            color: .brandPremium
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 20)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always)) // Hide dots or .always
            .padding(.vertical, -20)
            .frame(height: highlightCardHeight + 40) // Card height + vertical padding
        }
    }
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.brandSerif(20))
            .foregroundStyle(Color.coffeeDark)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }
    
    private var greetingText: String {
        switch appState.timeMode {
        case .morning: return "Good Morning"
        case .day: return "Good Afternoon"
        case .evening: return "Good Evening"
        }
    }
    

}

// MARK: - Subviews

struct HighlightCard: View {
    let title: String
    let subtitle: String
    let icon: String // Asset name
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(icon)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(color)
                    .padding(8)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.brandSans(16))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.coffeeDark)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}



struct ActiveOrderCard: View {
    let order: Order
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("ACTIVE ORDER")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.brandAccent)
                
                Text((order.status ?? "Unknown").uppercased())
                .font(.brandSerif(20))
                .foregroundStyle(Color.white)
                
                Text("\(order.deliveryOption.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) • \(order.total.toVND())")
                .font(.brandSans(14))
                .foregroundStyle(Color.white.opacity(0.8))
            }
            Spacer()
            Image("arrow_right_circle")
            .resizable()
            .renderingMode(.template)
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

#Preview {
    HomeView()
        .environmentObject(AppState())
}
