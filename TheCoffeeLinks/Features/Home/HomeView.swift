import SwiftUI
import CachedAsyncImage

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var trackingViewModel: OrderTrackingViewModel

    @State private var productForCustomization: Product?

    var body: some View {
        ZStack {
            BaseViewColor.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, BaseViewLayout.screenInset)
                        .padding(.top, BaseViewLayout.screenTopInset)

                    if !homeViewModel.vouchers.isEmpty {
                        Spacer().frame(height: 10)
                        VoucherCarouselSection(vouchers: homeViewModel.vouchers)
                        Spacer().frame(height: 57)
                    } else {
                        Spacer().frame(height: 24)
                    }

                    PopularSection(
                        products: homeViewModel.popularProducts,
                        horizontalPadding: BaseViewLayout.screenInset,
                        onSeeAll: { appState.selectedTab = 1 },
                        onBuyNow: { productForCustomization = $0 }
                    )

                    Spacer().frame(height: BaseViewLayout.majorSectionGap)

                    EventsSection(
                        events: homeViewModel.events,
                        horizontalPadding: BaseViewLayout.screenInset
                    )
                }
                .padding(.bottom, BaseViewLayout.screenInset)
            }
            .refreshable {
                await homeViewModel.refresh()
                await trackingViewModel.fetchActiveOrders()
            }
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                trackingViewModel.setUserId(user.id)
            }
        }
        .onChange(of: authViewModel.currentUser) { newUser in
            if let user = newUser {
                trackingViewModel.setUserId(user.id)
            }
        }
        .sheet(isPresented: $trackingViewModel.showingPaymentWebView) {
            if let url = trackingViewModel.paymentUrl {
                PaymentWebView(url: url) { result in
                    trackingViewModel.handlePaymentResult(result)
                } onCancel: {
                    trackingViewModel.showingPaymentWebView = false
                }
            }
        }
        .sheet(item: $productForCustomization) { product in
            ProductDetailSheet(product: product)
                .environmentObject(menuViewModel)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("The Coffee Links")
                .font(BaseViewFont.screenTitle)
                .foregroundStyle(BaseViewColor.textPrimary)

            Text("Chào buổi sáng, \(authViewModel.currentUser?.displayName ?? String(localized: "guest_name"))")
                .font(BaseViewFont.screenSubtitle)
                .lineSpacing(6)
                .foregroundStyle(BaseViewColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct VoucherCarouselSection: View {
    let vouchers: [Voucher]
    @State private var selectedIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(vouchers.enumerated()), id: \.element.id) { index, voucher in
                    CachedAsyncImage(url: URL(string: voucher.imageUrl ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Rectangle()
                                .fill(BaseViewColor.placeholder)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .aspectRatio(2, contentMode: .fit)
            .onChange(of: vouchers.count) { count in
                if count > 0 {
                    selectedIndex = min(selectedIndex, max(0, count - 1))
                } else {
                    selectedIndex = 0
                }
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Rectangle()
                        .fill(index == normalizedIndex ? BaseViewColor.indicatorActive : BaseViewColor.indicatorInactive)
                        .frame(width: 40, height: 5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var normalizedIndex: Int {
        return selectedIndex % 3
    }
}

private struct PopularSection: View {
    let products: [PopularProduct]
    let horizontalPadding: CGFloat
    let onSeeAll: () -> Void
    let onBuyNow: (Product) -> Void
    @State private var containerWidth: CGFloat = UIScreen.main.bounds.width

    var body: some View {
        let availableWidth = max(0, containerWidth - (horizontalPadding * 2))
        let cardWidth = min(300, availableWidth)

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Bán chạy")
                    .font(BaseViewFont.sectionTitle)
                    .foregroundStyle(BaseViewColor.textPrimary)

                Spacer()

                Button(action: onSeeAll) {
                    BaseUnderlinedCTA(title: "XEM TẤT CẢ")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, horizontalPadding)

            Spacer().frame(height: 26)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if products.isEmpty {
                        PopularProductCard(product: nil, cardWidth: cardWidth, onBuyNow: onBuyNow)
                        PopularProductCard(product: nil, cardWidth: cardWidth, onBuyNow: onBuyNow)
                    } else {
                        ForEach(products.prefix(8), id: \.id) { product in
                            PopularProductCard(product: product, cardWidth: cardWidth, onBuyNow: onBuyNow)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { containerWidth = geometry.size.width }
                    .onChange(of: geometry.size.width) { newWidth in
                        containerWidth = newWidth
                    }
            }
        )
    }
}

private struct PopularProductCard: View {
    let product: PopularProduct?
    let cardWidth: CGFloat
    let onBuyNow: (Product) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let product, let urlString = product.product.displayImageUrl, let url = URL(string: urlString) {
                        CachedAsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Rectangle().fill(BaseViewColor.placeholder)
                            }
                        }
                    } else {
                        Rectangle().fill(BaseViewColor.placeholder)
                    }
                }
                .frame(width: cardWidth, height: cardWidth)
                .clipped()

                Text(priceText)
                    .font(BaseViewFont.labelStrong)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .background(BaseViewColor.elevatedSurface)
                    .padding(.leading, BaseViewLayout.badgeInset)
                    .padding(.bottom, BaseViewLayout.badgeInset)
            }

            VStack(alignment: .leading, spacing: 0) {
                TwoLineText(
                    text: (product?.product.name ?? "COLDBREW CHANH VÀNG").uppercased(),
                    font: BaseViewFont.cardTitle,
                    color: BaseViewColor.textPrimary,
                    height: BaseViewLayout.cardTitleTwoLineHeight
                )

                Spacer().frame(height: 24)

                Button {
                    if let product {
                        onBuyNow(product.product)
                    }
                }
                label: {
                    BaseUnderlinedCTA(title: "MUA NGAY")
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, BaseViewLayout.contentInset)
            .padding(.top, BaseViewLayout.contentInset)
            .padding(.bottom, BaseViewLayout.contentInset)
            .frame(width: cardWidth, alignment: .topLeading)
        }
        .frame(width: cardWidth, alignment: .topLeading)
        .overlay(
            Rectangle()
                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if let product {
                onBuyNow(product.product)
            }
        }
    }

    private var priceText: String {
        if let product {
            return product.product.price(for: .medium).toVND().replacingOccurrences(of: "₫", with: "đ")
        }
        return "56.000đ"
    }
}

private struct EventsSection: View {
    let events: [Event]
    let horizontalPadding: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sự kiện")
                .font(BaseViewFont.sectionTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(.horizontal, horizontalPadding)

            Spacer().frame(height: 26)

            EventPager(events: events, horizontalPadding: horizontalPadding)
        }
    }
}

private struct EventPager: View {
    let events: [Event]
    let horizontalPadding: CGFloat
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isHorizontalDrag = false
    private let itemSpacing: CGFloat = 0

    private var pagerEvents: [Event?] {
        if events.isEmpty {
            return [nil, nil]
        }
        return events.map { Optional($0) }
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = max(0, geometry.size.width - (horizontalPadding * 2))
            let cardHeight = cardWidth * 4 / 3
            let totalCardHeight = cardHeight + (BaseViewLayout.inlineCTAHeight / 2)
            let pageStride = cardWidth + itemSpacing

            HStack(spacing: itemSpacing) {
                ForEach(Array(pagerEvents.enumerated()), id: \.offset) { _, event in
                    EventCard(event: event, cardWidth: cardWidth, cardHeight: cardHeight)
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
            .offset(x: -CGFloat(currentIndex) * pageStride + dragOffset + horizontalPadding)
            .clipped()
            .simultaneousGesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onChanged { value in
                        let x = value.translation.width
                        let y = value.translation.height

                        if !isHorizontalDrag {
                            if abs(x) <= abs(y) * 1.35 { return }
                            isHorizontalDrag = true
                        }

                        guard isHorizontalDrag else { return }
                        dragOffset = x
                    }
                    .onEnded { value in
                        defer {
                            isHorizontalDrag = false
                        }

                        guard isHorizontalDrag else {
                            dragOffset = 0
                            return
                        }

                        let projected = value.predictedEndTranslation.width
                        let delta = (-projected / pageStride)
                        let rawTarget = CGFloat(currentIndex) + delta
                        let target = Int(round(rawTarget))
                        let clamped = min(max(0, target), max(0, pagerEvents.count - 1))

                        withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.86)) {
                            currentIndex = clamped
                            dragOffset = 0
                        }
                    },
                including: .gesture
            )
            .frame(height: totalCardHeight)
        }
        .onChange(of: events.count) { _ in
            currentIndex = min(currentIndex, max(0, pagerEvents.count - 1))
        }
        .frame(height: (UIScreen.main.bounds.width - (horizontalPadding * 2)) * 4 / 3 + (BaseViewLayout.inlineCTAHeight / 2))
    }
}

private struct EventCard: View {
    let event: Event?
    let cardWidth: CGFloat
    let cardHeight: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let event, let urlString = event.imageUrl, let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Rectangle().fill(BaseViewColor.placeholder)
                        }
                    }
                } else {
                    Rectangle().fill(BaseViewColor.placeholder)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipped()

            VStack(alignment: .leading, spacing: 5) {
                Text(event?.title ?? "Đêm nhạc Bolero")
                    .font(BaseViewFont.sectionTitle)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 5)
                    .background(BaseViewColor.elevatedSurface)

                Text(displayDate)
                    .font(BaseViewFont.labelStrong)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .background(BaseViewColor.elevatedSurface)
            }
            .padding(.leading, BaseViewLayout.badgeInset)
            .padding(.top, BaseViewLayout.badgeInset)

            Button {
            }
            label: {
                BaseUnderlinedCTA(title: "XEM THÊM")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 17)
                    .background(BaseViewColor.elevatedSurface)
                    .overlay(
                        Rectangle().stroke(BaseViewColor.textPrimary, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .frame(width: max(0, cardWidth - (BaseViewLayout.badgeInset * 2)))
            .offset(
                x: BaseViewLayout.badgeInset,
                y: cardHeight - (BaseViewLayout.inlineCTAHeight / 2)
            )
        }
        .frame(
            width: cardWidth,
            height: cardHeight + (BaseViewLayout.inlineCTAHeight / 2),
            alignment: .topLeading
        )
    }

    private var displayDate: String {
        guard let date = event?.date else { return "01/05/2026" }
        return HomeDateFormatter.value.string(from: date)
    }
}

private enum HomeDateFormatter {
    static let value: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
}

