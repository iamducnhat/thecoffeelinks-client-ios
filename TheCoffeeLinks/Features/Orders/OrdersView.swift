//
//  OrdersView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel(repository: DependencyContainer.shared.orderRepository)
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0 // 0: Active, 1: History
    @State private var scrollOffset = CGFloat.zero
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            // Fixed Navigation Header
            HStack(alignment: .center, spacing: AppLayout.spacing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(AppFont.navIcon)
                        .foregroundStyle(Color.textInk)
                        .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                        .background {
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .fill(Color.backgroundPaper)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.textInk, lineWidth: min(66.6, max(scrollOffset, 0.0)) / 66.6)
                                .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                        }
                }
                
                Text("orders_title")
                    .font(AppFont.displayTitle)
                    .lineLimit(1)
                    .foregroundStyle(Color.textInk)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hidden()
            }
            .frame(minHeight: AppLayout.touchTarget)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, AppLayout.spacing)
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Navigation Header (Scrollable)
                    HStack(alignment: .center, spacing: AppLayout.spacing) {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textInk)
                            .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                            .hidden()
                        
                        Text("orders_title")
                            .font(AppFont.displayTitle)
                            .lineLimit(1)
                            .foregroundStyle(Color.textInk)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: AppLayout.touchTarget)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, AppLayout.spacing)
                    .overlay(alignment: .bottom) {
                        Color.secondary.frame(height: 1, alignment: .top)
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    LazyVStack(spacing: AppLayout.spacing) {
                        // Tab Selector
                        HStack(spacing: 0) {
                            OrderTabButton(title: String(localized: "orders_tab_active"), isSelected: selectedTab == 0) {
                                selectedTab = 0
                            }
                            OrderTabButton(title: String(localized: "orders_tab_history"), isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.textInk, lineWidth: 1)
                        )
                        
                        // Content
                        if viewModel.isLoading {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(0..<5, id: \.self) { i in
                                    Text(String(localized: "order_fetching_status \(i+1)"))
                                        .font(AppFont.uiMicro)
                                        .foregroundStyle(Color.primaryEspresso)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppLayout.spacing)
                            .background(Color.backgroundPaper)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.primaryEspresso, lineWidth: 1)
                            )
                        } else {
                            let orders = selectedTab == 0 ? viewModel.activeOrders : viewModel.historyOrders
                            if orders.isEmpty {
                                VStack(spacing: AppLayout.spacing) {
                                    Text("orders_empty_title")
                                        .font(AppFont.sectionHeader)
                                        .foregroundStyle(Color.textInk)
                                    Text("orders_empty_message")
                                        .font(AppFont.body)
                                        .foregroundStyle(Color.textMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.border, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                                )
                            } else {
                                ForEach(orders) { order in
                                    NavigationLink {
                                        OrderDetailView(order: order)
                                    } label: {
                                        OrderRow(order: order)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppLayout.spacing)
                    .padding(.bottom, 40)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
            }
            .zIndex(-Double.infinity)
        }
        .onAppear { viewModel.fetchOrders() }
    }
}

// MARK: - Tab Button

struct OrderTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.monoBody)
                .foregroundColor(isSelected ? Color.backgroundPaper : Color.textInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.primaryEspresso : Color.backgroundPaper)
        }
    }
}

// MARK: - Order Row

struct OrderRow: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
            HStack {
                Text(String(localized: "order_number_format \(order.id.prefix(8).uppercased())"))
                    .font(AppFont.monoBody.bold())
                    .foregroundStyle(Color.textInk)
                Spacer()
                Text(order.totalAmount.formattedVND)
                    .font(AppFont.monoBody)
                    .foregroundStyle(Color.primaryEspresso)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "order_placed_on_format \(order.createdAt.formatted(.dateTime.month().day().hour().minute()))"))
                        .font(AppFont.uiMicro)
                    Text(order.status.displayName.uppercased())
                        .font(AppFont.monoBody)
                        .foregroundStyle(statusColor)
                }
                .foregroundStyle(Color.textMuted)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding(AppLayout.spacing)
        .background(Color.backgroundPaper)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        if order.status.isActive { return Color.primaryEspresso }
        if order.status == .cancelled { return Color.semanticError }
        return Color.textMuted
    }
}
