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
    
    // Add this property to control header mode
    var isPresentedModally: Bool = true
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            
            // Fixed Navigation Header
            HStack(alignment: .center, spacing: AppLayout.spacing) {
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .padding(12)
                        .background {
                            Circle()
                                .fill(Color.bgPrimary)
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(Color.textPrimary, lineWidth: 1)
                                .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                        }
                }
                
                // Fade in the inline title as the list scrolls
                Text(String(localized: "orders_title"))
                    .font(AppTypography.displayMedium)
                    .lineLimit(1)
                    .foregroundColor(Color.textPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .hidden()
            }
            .frame(minHeight: AppLayout.touchTarget)
            .padding(.horizontal, AppLayout.spacing)
            .padding(.top, 8)
            .zIndex(1)
            .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Navigation Header (Scrollable)
                    VStack(spacing: AppLayout.marginCompact) {
                        HStack(alignment: .center, spacing: AppLayout.spacing) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                                .padding(12)
                                //.hidden()
                            
                            Text(String(localized: "orders_title"))
                                .font(AppTypography.displayMedium)
                                .lineLimit(1)
                                .foregroundColor(Color.textPrimary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        
                        Divider()
                            .background(Color.borderSecondary)
                            .padding(.horizontal, -AppLayout.spacing)
                    }
                    .padding(.horizontal, AppLayout.spacing)
                    .padding(.top, AppLayout.spacingCompact)
                    .background(Color.bgPrimary)
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
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                .strokeBorder(Color.textPrimary, lineWidth: 1)
                        )
                        
                        // Content
                        if viewModel.isLoading {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(0..<5, id: \.self) { i in
                                    Text(String(localized: "order_fetching_status \(i+1)"))
                                        .font(AppFont.uiMicro)
                                        .foregroundStyle(Color.accentPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppLayout.spacing)
                            .background(Color.bgPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                    .strokeBorder(Color.accentPrimary, lineWidth: 1)
                            )
                        } else {
                            let orders = selectedTab == 0 ? viewModel.activeOrders : viewModel.historyOrders
                            if orders.isEmpty {
                                VStack(spacing: AppLayout.spacing) {
                                    Text(String(localized: "orders_empty_title"))
                                        .font(AppFont.sectionHeader)
                                        .foregroundStyle(Color.textPrimary)
                                    Text(String(localized: "orders_empty_message"))
                                        .font(AppFont.body)
                                        .foregroundStyle(Color.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(60)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                        .strokeBorder(Color.border, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
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
            .zIndex(0)
        }
        .onAppear { viewModel.fetchOrders() }
        .navigationBarHidden(true)
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
                .foregroundColor(isSelected ? Color.bgPrimary : Color.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.accentPrimary : Color.bgPrimary)
        }
    }
}

// MARK: - OrderRow

struct OrderRow: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
            HStack {
                Text(String(localized: "order_number_format \(order.id.prefix(8).uppercased())"))
                    .font(AppFont.monoBody.bold())
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(order.totalAmount.formattedVND)
                    .font(AppFont.monoBody)
                    .foregroundStyle(Color.accentPrimary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "order_placed_on_format \(order.createdAt.formatted(.dateTime.month().day().hour().minute()))"))
                        .font(AppFont.uiMicro)
                    Text(order.status.displayName.uppercased())
                        .font(AppFont.monoBody)
                        .foregroundStyle(statusColor)
                }
                .foregroundStyle(Color.textSecondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(AppLayout.spacing)
        .background(Color.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .strokeBorder(Color.border, lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        if order.status.isActive { return Color.accentPrimary }
        if order.status == .cancelled { return Color.stateError }
        return Color.textSecondary
    }
}
