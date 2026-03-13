//
//  OrderHistoryView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct OrderHistoryView: View {
    // Mock history
    let history = [
        Order(id: "1", userId: "u1", storeId: "s1", status: .completed,
              mode: .pickup, paymentMethod: .applePay,
              items: [], subtotal: 10.0, deliveryFee: 0, discount: 0, totalAmount: 10.0,
              tableId: nil, deliveryAddress: nil, deliveryNotes: nil, staffNotes: nil,
              createdAt: Date(), updatedAt: Date(),
              estimatedReadyAt: nil, completedAt: Date(), cancelledAt: nil, cancellationReason: nil, paymentUrl: nil,
              tax: 0, taxRate: 0, pointsUsed: 0, voucherSnapshot: nil, storeSnapshot: nil),

        Order(id: "2", userId: "u1", storeId: "s1", status: .cancelled,
              mode: .delivery, paymentMethod: .card,
              items: [], subtotal: 15.0, deliveryFee: 2.0, discount: 0, totalAmount: 17.0,
              tableId: nil, deliveryAddress: nil, deliveryNotes: nil, staffNotes: nil,
              createdAt: Date().addingTimeInterval(-86400), updatedAt: Date(),
              estimatedReadyAt: nil, completedAt: nil, cancelledAt: Date(), cancellationReason: "Changed mind", paymentUrl: nil,
              tax: 0, taxRate: 0, pointsUsed: 0, voucherSnapshot: nil, storeSnapshot: nil)
    ]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            
            // Fixed Navigation Header
            HStack(alignment: .center, spacing: AppLayout.spacing) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(AppFont.navIcon)
                        .foregroundStyle(Color.textPrimary)
                        .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                }
                
                Text(String(localized: "history_title"))
                    .font(AppFont.displayTitle)
                    .lineLimit(1)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: AppLayout.touchTarget)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, AppLayout.spacing)
            .background(Color.bgPrimary)
            .overlay(alignment: .bottom) {
                Color.secondary.frame(height: 1)
            }
            .zIndex(1)
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)
                    
                    if history.isEmpty {
                        VStack(spacing: AppLayout.spacing) {
                            Text(String(localized: "orders_empty_generic"))
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            Text(String(localized: "orders_empty_description"))
                                .font(AppFont.uiCaption)
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(60)
                    } else {
                        LazyVStack(spacing: AppLayout.spacing) {
                            ForEach(history) { order in
                                OrderHistoryRow(order: order)
                            }
                        }
                        .padding(AppLayout.spacing)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct OrderHistoryRow: View {
    let order: Order
    
    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.createdAt.formatted(.dateTime.day().month().year()))
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.textSecondary)
                    
                    Text(order.storeId) // Ideally fetch store name
                        .font(AppFont.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("\(order.items.count) items")
                        .font(AppFont.body)
                        .foregroundStyle(Color.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(order.totalAmount.formattedVND)
                        .font(AppFont.monoBody)
                        .foregroundStyle(Color.accentPrimary)
                    
                    Text(order.status.displayName)
                        .font(AppFont.uiMicro)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.1))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.leading, 8)
            }
            .padding(AppLayout.spacing)
            .background(Color.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .strokeBorder(Color.border, lineWidth: 1)
            )
            
            // Hit testing for potential navigation
            NavigationLink(destination: OrderDetailView(order: order)) {
                EmptyView()
            }
            .opacity(0)
        }
        .buttonStyle(.plain)
    }
    
    private var statusColor: Color {
        switch order.status {
        case .completed: return Color.textSecondary
        case .cancelled: return Color.stateError
        default: return Color.stateSuccess
        }
    }
}
