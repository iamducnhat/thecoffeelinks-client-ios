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
                    ProgressView()
                } else {
                    GeometryReader { g in
                        ScrollView {
                            // Header - scrolls with content
                            HStack {
                                Text("Orders")
                                    .font(.brandSerif(32))
                                    .foregroundStyle(Color.brandPrimary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            List {
                                // Active Orders Section
                                if !viewModel.activeOrders.isEmpty {
                            Section {
                                ForEach(viewModel.activeOrders) { order in
                                    LiveOrderCard(order: order)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                }
                            } header: {
                                Text("Active Orders")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.secondary)
                                    .textCase(nil)
                            }
                        }
                        
                        // History Section
                        Section {
                            if viewModel.pastOrders.isEmpty {
                                VStack(spacing: 12) {
                                    Image("coffee")
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)
                                        .foregroundStyle(Color.secondary.opacity(0.5))
                                    Text("No recent orders")
                                        .font(.brandSans(14))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .listRowBackground(Color.clear)
                            } else {
                                ForEach(viewModel.pastOrders) { order in
                                    NavigationLink(destination: OrderDetailView(order: order)) {
                                        HistoryRow(order: order)
                                    }
                                    .listRowBackground(Color.white)
                                }
                                .onDelete { indexSet in
                                    // Optional: handle delete action
                                    // viewModel.deleteOrders(at: indexSet)
                                }
                            }
                        } header: {
                            Text("Recent Visits")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.secondary)
                                .textCase(nil)
                        }
                        
                        // View All Section
                        Section {
                            Button {
                                // Load more orders action
                            } label: {
                                Text("View All Orders")
                                    .font(.brandSans(14))
                                    .foregroundStyle(Color.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                    .frame(width: g.size.width, height: g.size.height - 60, alignment: .center)
                        }
                    }
                }
            }
            .task {
                await viewModel.fetchOrders()
            }
        }
    }
}
    


// MARK: - Order Detail View (Placeholder)
struct OrderDetailView: View {
    let order: Order
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                itemsSection
                summarySection
                reorderButton
            }
            .padding()
        }
        .background(Color.brandBackground)
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Order #\(String(order.id.prefix(8)))")
                .font(.brandSerif(24))
                .foregroundStyle(Color.coffeeDark)
            
            if let status = order.status {
                Text(status.capitalized)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(status == "completed" ? Color.sage : Color.coffeeRich.opacity(0.2))
                    .foregroundStyle(status == "completed" ? .white : Color.coffeeDark)
                    .clipShape(Capsule())
            }
            
            if let date = order.createdAt {
                Text(date)
                    .font(.brandSans(14))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.brandSerif(18))
                .foregroundStyle(Color.coffeeDark)
            
            ForEach(order.items, id: \.id) { item in
                ItemRow(item: item)
                if item.id != order.items.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Delivery")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(order.deliveryOption.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .fontWeight(.medium)
            }
            .font(.brandSans(14))
            
            if let address = order.deliveryAddress {
                HStack {
                    Text("Address")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(address)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                .font(.brandSans(14))
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.brandSerif(18))
                    .foregroundStyle(Color.coffeeDark)
                Spacer()
                Text(order.total.toVND())
                    .font(.brandSerif(18))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.brandPrimary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var reorderButton: some View {
        LiquidGlassPrimaryButton("Order Again", icon: "clock") {
            // Reorder action
        }
        .padding(.top, 8)
    }
}

private struct ItemRow: View {
    let item: OrderItem
    
    var body: some View {
        HStack(spacing: 12) {
            if let imageUrl = item.productImage, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.productName ?? "Item")
                    .font(.brandSans(16))
                    .foregroundStyle(Color.coffeeDark)
                Text("Qty: \(item.quantity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text((item.finalPrice ?? 0).toVND())
                .font(.brandSans(14))
                .fontWeight(.semibold)
                .foregroundStyle(Color.coffeeDark)
        }
        .padding(.vertical, 8)
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.coffeeRich.opacity(0.1))
            .frame(width: 50, height: 50)
            .overlay {
                Image("coffee")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.coffeeRich.opacity(0.3))
            }
    }
}

// MARK: - Live Order Card
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
                        .renderingMode(.template)
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

// MARK: - History Row (for List)
struct HistoryRow: View {
    let order: Order
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image (first item's image if available)
            if let firstItem = order.items.first, let imageUrl = firstItem.productImage, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure(_), .empty:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(order.createdAt ?? "Just now")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.secondary)
                
                // Show delivery option or address instead of items
                Text(order.deliveryAddress ?? order.deliveryOption.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.brandSans(16))
                    .foregroundStyle(Color.coffeeDark)
                    .lineLimit(1)
                
                // Show item count if available
                if !order.items.isEmpty {
                    Text("\(order.items.count) item\(order.items.count != 1 ? "s" : "")")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer()
            
            Text(order.total.toVND())
                .font(.brandSans(14))
                .fontWeight(.bold)
                .foregroundStyle(Color.coffeeDark)
        }
        .padding(.vertical, 4)
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.coffeeRich.opacity(0.1))
            .frame(width: 50, height: 50)
            .overlay {
                Image("coffee")
                    .resizable()
                    .renderingMode(.template) 
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.coffeeRich.opacity(0.3))
            }
    }
}

#Preview {
    OrdersView()
}
