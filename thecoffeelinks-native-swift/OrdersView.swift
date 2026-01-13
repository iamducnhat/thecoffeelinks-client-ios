//
//  OrdersView.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBackground.ignoresSafeArea()
                
                if viewModel.viewState == .loading && viewModel.activeOrders.isEmpty && viewModel.pastOrders.isEmpty {
                    skeletonView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            header
                            
                            // Live Activity Section (Active Orders)
                            if !viewModel.activeOrders.isEmpty {
                                ForEach(viewModel.activeOrders) { order in
                                    LiveOrderCard(order: order)
                                }
                            }
                            
                            // History Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Visits")
                                    .font(.brandSerif(20))
                                    .foregroundStyle(Color.coffeeDark)
                                
                                if viewModel.pastOrders.isEmpty {
                                    Text("No recent orders")
                                        .font(.brandSans(14))
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(viewModel.pastOrders) { order in
                                        HistoryItem(order: order)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.fetchOrders()
                    }
                }
            }
            .task {
                await viewModel.fetchOrders()
            }
        }
    }
    
    var header: some View {
        HStack {
            Text("Orders")
                .font(.brandSerif(32))
                .foregroundStyle(Color.brandPrimary)
            Spacer()
        }
    }
    
    var skeletonView: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                
                ForEach(0..<2) { _ in
                    LiveOrderCard(order: .placeholder)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Visits")
                        .font(.brandSerif(20))
                        .foregroundStyle(Color.coffeeDark)
                    
                    ForEach(0..<3) { _ in
                        HistoryItem(order: .placeholder)
                    }
                }
            }
            .padding()
        }
        .redacted(reason: .placeholder)
        .disabled(true)
    }
}

struct LiveOrderCard: View {
    let order: Order
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Order #\(String(order.id.prefix(8)))")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white.opacity(0.8))
                
                Spacer()
                
                Text((order.status ?? "Unknown").capitalized)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.sage)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                // Animated Pulse Icon
                ZStack {
                    Circle()
                        .fill(Color.sage.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image("coffee")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.sage)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.deliveryOption.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.brandSans(16))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                    
                    Text("Total: \(order.total.toVND())")
                        .font(.brandSans(14))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Progress Bar simulation
            let progress: Double = {
                guard let status = order.status else { return 0.0 }
                switch status {
                case "placed", "received": return 0.3
                case "preparing": return 0.5
                case "ready": return 0.8
                case "completed": return 1.0
                case "cancelled": return 0.0
                default: return 0.1
                }
            }()
            
            ProgressView(value: progress)
                .tint(Color.sage)
                .background(Color.white.opacity(0.1))
        }
        .padding(20)
        .background(Color.coffeeDark)
        .cornerRadius(24)
        .shadow(color: Color.coffeeDark.opacity(0.3), radius: 12, x: 0, y: 8)
    }
}

struct HistoryItem: View {
    let order: Order
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.createdAt ?? "Just now")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.secondary)
                
                // Show delivery option or address instead of items (which we don't have)
                Text(order.deliveryAddress ?? order.deliveryOption.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.brandSans(16))
                    .foregroundStyle(Color.coffeeDark)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(order.total.toVND())
                .font(.brandSans(16))
                .fontWeight(.bold)
                .foregroundStyle(Color.coffeeDark)
            
            Image("chevron_right")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .foregroundStyle(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

#Preview {
    OrdersView()
}
