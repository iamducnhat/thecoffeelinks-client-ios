//
//  OrdersView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel(repository: DependencyContainer.shared.orderRepository)
    @Environment(\.dismiss) private var dismiss
    @State private var cancellationOrder: Order?

    var isPresentedModally: Bool = true

    var body: some View {
        ZStack {
            BaseViewColor.background.ignoresSafeArea()

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: OrderViewMetrics.sectionGap) {
                    header

                    VStack(alignment: .leading, spacing: OrderViewMetrics.cardTopGap) {
                        Text("Đơn hàng hiện tại")
                            .font(OrderViewFonts.sectionTitle)
                            .foregroundStyle(BaseViewColor.textPrimary)

                        activeOrdersContent
                    }

                    VStack(alignment: .leading, spacing: OrderViewMetrics.cardTopGap) {
                        Text("Lịch sử đơn hàng")
                            .font(OrderViewFonts.sectionTitle)
                            .foregroundStyle(BaseViewColor.textPrimary)

                        historyOrdersContent
                    }
                }
                .padding(.horizontal, OrderViewMetrics.pagePadding)
                .padding(.top, OrderViewMetrics.topPadding)
                .padding(.bottom, OrderViewMetrics.bottomPadding)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear { viewModel.fetchOrders() }
        .sheet(item: $cancellationOrder) { order in
            OrderCancellationSheet(
                order: order,
                isLoading: viewModel.isCancelling(order),
                errorMessage: viewModel.cancellationError
            ) {
                Task {
                    if await viewModel.cancelOrder(order) {
                        cancellationOrder = nil
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        ZStack {
            Text("Đơn hàng")
                .font(OrderViewFonts.title)
                .foregroundStyle(BaseViewColor.textPrimary)
                .frame(maxWidth: .infinity)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(BaseViewColor.accentForeground)
                        .frame(width: OrderViewMetrics.navButtonSize, height: OrderViewMetrics.navButtonSize)
                        .background(BaseViewColor.accent)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .frame(minHeight: OrderViewMetrics.navButtonSize)
    }

    @ViewBuilder
    private var activeOrdersContent: some View {
        if viewModel.isLoading {
            OrderLoadingCard()
        } else if viewModel.activeOrders.isEmpty {
            OrderEmptyCard(title: "Không có đơn hàng hiện tại")
        } else {
            VStack(spacing: OrderViewMetrics.sectionGap) {
                ForEach(viewModel.activeOrders) { order in
                    ActiveOrderReceiptCard(order: order) {
                        cancellationOrder = order
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var historyOrdersContent: some View {
        if viewModel.isLoading {
            OrderLoadingCard()
        } else if viewModel.historyOrders.isEmpty {
            OrderEmptyCard(title: "Chưa có lịch sử đơn hàng")
        } else {
            VStack(spacing: OrderViewMetrics.cardTopGap) {
                ForEach(viewModel.historyOrders) { order in
                    OrderReceiptHistoryRow(order: order)
                }
            }
        }
    }
}

private enum OrderViewMetrics {
    static let tiny: CGFloat = 5
    static let contentInset: CGFloat = 13
    static let pagePadding: CGFloat = 23
    static let sectionGap: CGFloat = 40
    static let cardTopGap: CGFloat = 23
    static let topPadding: CGFloat = 23
    static let bottomPadding: CGFloat = 40
    static let navButtonSize: CGFloat = 23
    static let borderWidth: CGFloat = 1
    static let statusHeight: CGFloat = 26
    static let progressHeight: CGFloat = 3
    static let itemMinHeight: CGFloat = 116
    static let cancelButtonMinHeight: CGFloat = 38
}

private enum OrderViewFonts {
    static let title = Font.custom("BeVietnamPro-Bold", size: 22)
    static let sectionTitle = Font.custom("BeVietnamPro-Medium", size: 18)
    static let itemTitle = Font.custom("BeVietnamPro-Medium", size: 18)
    static let body = Font.custom("BeVietnamPro-Regular", size: 14)
    static let mono = Font.custom("BeVietnamPro-Medium", size: 14)
    static let total = Font.custom("BeVietnamPro-Bold", size: 18)
    static let cta = Font.custom("BeVietnamPro-Medium", size: 14)
}

private struct ActiveOrderReceiptCard: View {
    let order: Order
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            statusHeader

            VStack(spacing: 0) {
                ForEach(Array(order.items.enumerated()), id: \.element.id) { index, item in
                    OrderReceiptItemRow(item: item, isTinted: index.isMultiple(of: 2))
                }
            }

            Text("Tổng: \(order.totalAmount.formattedVND)")
                .font(OrderViewFonts.total)
                .foregroundStyle(BaseViewColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, OrderViewMetrics.contentInset)
                .padding(.vertical, OrderViewMetrics.contentInset)

            if order.canShowCancelButton {
                Button(action: onCancel) {
                    Text("HUỶ ĐƠN")
                        .font(OrderViewFonts.cta)
                        .tracking(2)
                        .foregroundStyle(BaseViewColor.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, OrderViewMetrics.contentInset)
                        .frame(minHeight: OrderViewMetrics.cancelButtonMinHeight)
                        .background(BaseViewColor.semanticError)
                }
                .buttonStyle(.plain)
            }
        }
        .background(BaseViewColor.background)
        .overlay {
            Rectangle()
                .strokeBorder(BaseViewColor.border, lineWidth: OrderViewMetrics.borderWidth)
        }
    }

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: OrderViewMetrics.contentInset) {
            Text(statusText)
                .font(OrderViewFonts.mono)
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(BaseViewColor.background)
                .padding(.horizontal, OrderViewMetrics.tiny)
                .padding(.vertical, 5)
                .frame(minHeight: OrderViewMetrics.statusHeight)
                .background(BaseViewColor.accent)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    BaseViewColor.borderSecondary.opacity(0.35)
                    BaseViewColor.accent
                        .frame(width: max(OrderViewMetrics.borderWidth, geometry.size.width * progress))
                }
            }
            .frame(height: OrderViewMetrics.progressHeight)

            Text("DỰ KIẾN: \(estimatedMinutes) PHÚT")
                .font(OrderViewFonts.mono)
                .tracking(2)
                .foregroundStyle(BaseViewColor.textPrimary)
        }
        .padding(.horizontal, OrderViewMetrics.contentInset)
        .padding(.top, OrderViewMetrics.contentInset)
        .padding(.bottom, OrderViewMetrics.contentInset)
    }

    private var statusText: String {
        switch order.status {
        case .pending, .placed, .received, .preparing:
            return "ĐƠN HÀNG ĐANG ĐƯỢC CHUẨN BỊ"
        case .ready:
            return "ĐƠN HÀNG ĐÃ SẴN SÀNG"
        case .delivering:
            return "ĐƠN HÀNG ĐANG ĐƯỢC VẬN CHUYỂN"
        case .completed:
            return "ĐƠN HÀNG ĐÃ HOÀN THÀNH"
        case .cancelled:
            return "ĐƠN HÀNG ĐÃ HUỶ"
        }
    }

    private var progress: CGFloat {
        switch order.status {
        case .pending: return 0.1
        case .placed: return 0.25
        case .received: return 0.35
        case .preparing: return 0.5
        case .ready: return 0.75
        case .delivering: return 0.9
        case .completed: return 1
        case .cancelled: return 0
        }
    }

    private var estimatedMinutes: Int {
        guard let estimatedReadyAt = order.estimatedReadyAt else { return 36 }
        return max(1, Int(ceil(estimatedReadyAt.timeIntervalSince(Date()) / 60)))
    }
}

private struct OrderReceiptItemRow: View {
    let item: OrderItem
    let isTinted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: OrderViewMetrics.contentInset) {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.productName)
                    .font(OrderViewFonts.itemTitle)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(item.customization.displayText)
                    .font(OrderViewFonts.body)
                    .foregroundStyle(BaseViewColor.textSecondary)
                    .lineLimit(2)
            }

            HStack(alignment: .firstTextBaseline) {
                Text("SỐ LƯỢNG: \(item.quantity)")
                    .font(OrderViewFonts.mono)
                    .tracking(2)

                Spacer(minLength: OrderViewMetrics.contentInset)

                Text(item.totalPrice.formattedVND)
                    .font(OrderViewFonts.mono)
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(BaseViewColor.textPrimary)
        }
        .padding(.horizontal, OrderViewMetrics.contentInset)
        .padding(.vertical, OrderViewMetrics.contentInset)
        .frame(maxWidth: .infinity, minHeight: OrderViewMetrics.itemMinHeight, alignment: .topLeading)
        .background(isTinted ? BaseViewColor.accent.opacity(0.12) : BaseViewColor.background)
    }
}

private struct OrderReceiptHistoryRow: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: OrderViewMetrics.contentInset) {
            Text(order.totalAmount.formattedVND)
                .font(OrderViewFonts.total)
                .foregroundStyle(BaseViewColor.textPrimary)

            HStack(alignment: .firstTextBaseline) {
                Text(order.createdAt.orderReceiptTimestamp)
                    .font(OrderViewFonts.mono)
                    .tracking(2)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: OrderViewMetrics.contentInset)

                NavigationLink {
                    OrderDetailView(order: order)
                } label: {
                    Text("CHI TIẾT")
                        .font(OrderViewFonts.mono)
                        .tracking(2)
                        .underline()
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(OrderViewMetrics.contentInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BaseViewColor.background)
        .overlay {
            Rectangle()
                .strokeBorder(BaseViewColor.border, lineWidth: OrderViewMetrics.borderWidth)
        }
    }
}

private struct OrderCancellationSheet: View {
    let order: Order
    let isLoading: Bool
    let errorMessage: String?
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: OrderViewMetrics.cardTopGap) {
            Capsule()
                .fill(BaseViewColor.border)
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, OrderViewMetrics.contentInset)

            Text("Xác nhận huỷ đơn")
                .font(OrderViewFonts.title)
                .foregroundStyle(BaseViewColor.textPrimary)

            Text("Chúng tôi sẽ hoàn tiền cho các món trong đơn hàng này theo phương thức thanh toán ban đầu.")
                .font(OrderViewFonts.sectionTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(order.items) { item in
                    HStack(alignment: .top, spacing: OrderViewMetrics.contentInset) {
                        Text("\(item.quantity)x")
                            .font(OrderViewFonts.mono)
                            .tracking(1)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .frame(width: 40, alignment: .leading)

                        VStack(alignment: .leading, spacing: OrderViewMetrics.tiny) {
                            Text(item.productName)
                                .font(OrderViewFonts.itemTitle)
                                .foregroundStyle(BaseViewColor.textPrimary)

                            if !item.customization.displayText.isEmpty {
                                Text(item.customization.displayText)
                                    .font(OrderViewFonts.body)
                                    .foregroundStyle(BaseViewColor.textSecondary)
                            }
                        }

                        Spacer(minLength: OrderViewMetrics.contentInset)

                        Text(item.totalPrice.formattedVND)
                            .font(OrderViewFonts.mono)
                            .tracking(1)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .padding(.vertical, OrderViewMetrics.contentInset)

                    if item.id != order.items.last?.id {
                        Rectangle()
                            .fill(BaseViewColor.border)
                            .frame(height: OrderViewMetrics.borderWidth)
                    }
                }
            }
            .padding(.horizontal, OrderViewMetrics.contentInset)
            .overlay {
                Rectangle()
                    .strokeBorder(BaseViewColor.border, lineWidth: OrderViewMetrics.borderWidth)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(OrderViewFonts.body)
                    .foregroundStyle(BaseViewColor.semanticError)
            }

            Spacer(minLength: OrderViewMetrics.cardTopGap)
        }
        .padding(.horizontal, OrderViewMetrics.pagePadding)
        .background(BaseViewColor.background)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: OrderViewMetrics.contentInset) {
                Button(action: onConfirm) {
                    HStack(spacing: OrderViewMetrics.contentInset) {
                        if isLoading {
                            ProgressView()
                                .tint(BaseViewColor.background)
                        }

                        Text(isLoading ? "ĐANG HUỶ" : "XÁC NHẬN HUỶ ĐƠN")
                            .font(OrderViewFonts.cta)
                            .tracking(2)
                    }
                    .foregroundStyle(BaseViewColor.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, OrderViewMetrics.contentInset)
                    .background(BaseViewColor.semanticError)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                Button("Đóng") {
                    dismiss()
                }
                .font(OrderViewFonts.cta)
                .foregroundStyle(BaseViewColor.textPrimary)
                .disabled(isLoading)
            }
            .padding(.horizontal, OrderViewMetrics.pagePadding)
            .padding(.top, OrderViewMetrics.contentInset)
            .padding(.bottom, OrderViewMetrics.contentInset)
            .background(BaseViewColor.background)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

private struct OrderLoadingCard: View {
    var body: some View {
        Text("Đang xử lí...")
            .font(OrderViewFonts.sectionTitle)
            .foregroundStyle(BaseViewColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        .padding(OrderViewMetrics.contentInset)
        .overlay {
            Rectangle()
                .strokeBorder(BaseViewColor.border, lineWidth: OrderViewMetrics.borderWidth)
        }
    }
}

private struct OrderEmptyCard: View {
    let title: String

    var body: some View {
        Text(title)
            .font(OrderViewFonts.sectionTitle)
            .foregroundStyle(BaseViewColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(OrderViewMetrics.contentInset)
            .overlay {
                Rectangle()
                    .strokeBorder(BaseViewColor.border, lineWidth: OrderViewMetrics.borderWidth)
            }
    }
}

private extension Order {
    var canShowCancelButton: Bool {
        switch status {
        case .pending, .placed, .received, .preparing, .ready:
            return true
        case .delivering, .completed, .cancelled:
            return false
        }
    }
}

private extension Date {
    var orderReceiptTimestamp: String {
        OrderViewDateFormatter.receipt.string(from: self)
    }
}

private enum OrderViewDateFormatter {
    static let receipt: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss dd/MM/yyyy"
        return formatter
    }()
}
