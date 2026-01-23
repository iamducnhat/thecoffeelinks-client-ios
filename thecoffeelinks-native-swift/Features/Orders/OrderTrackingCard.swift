//
//  OrderTrackingCard.swift
//  thecoffeelinks-native-swift
//
//  Glanceable card for active order status
//

import SwiftUI

struct OrderTrackingCard: View {
    @StateObject var viewModel: OrderTrackingViewModel
    
    var body: some View {
        Group {
            if let order = viewModel.activeOrder {
                VStack(spacing: 0) {
                    // Header: Store & Status
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Order")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.statusMessage)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // Status Badge
                        Text(order.status.displayName)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(order.status))
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 4)
                            
                            Rectangle()
                                .fill(statusColor(order.status))
                                .frame(width: geo.size.width * viewModel.progress, height: 4)
                                .animation(.spring(), value: viewModel.progress)
                        }
                    }
                    .frame(height: 4)
                    
                    // Footer: Details & CTA
                    HStack {
                        // Product Preview
                        if let firstItem = order.items.first {
                            Text("\(firstItem.quantity)x \(firstItem.productName)" + (order.items.count > 1 ? " +\(order.items.count - 1) more" : ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // ETA
                        if let eta = order.estimatedReadyAt {
                            Label(timeString(from: eta), systemImage: "clock")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchActiveOrder()
            }
        }
    }
    
    private func statusColor(_ status: OrderStatus) -> Color {
        switch status {
        case .placed: return .blue
        // case .received: return .purple
        case .preparing: return .orange
        case .ready: return .green
        case .delivering: return .teal
        case .completed: return .gray
        case .cancelled: return .red
        case .pending: return .gray
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
