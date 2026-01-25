//
//  HomeView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Strictly aligned with canonical CheckoutView.swift
//  Section Order: Offers → Popular → Events
//

import SwiftUI
import CachedAsyncImage // CHANGED

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    
    // Tracking active orders
    @StateObject private var trackingViewModel = OrderTrackingViewModel(
        orderRepository: DependencyContainer.shared.orderRepository,
        realtimeService: DependencyContainer.shared.realtimeService
    )
    
    @State private var showAIModal = false
    @State private var scrollOffset = CGFloat.zero
    
    var body: some View {
        ZStack(alignment: .center) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical) { LazyVStack(spacing: 0) {
                    // MARK: Header
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(LocalizedStringKey("Hello, \(authViewModel.currentUser?.displayName ?? "GUEST")"))
                                    .font(AppFont.uiCaption)
                                    .foregroundStyle(Color.primaryEspresso)
                                
                                Text(LocalizedStringKey("The Coffee Links"))
                                    .font(AppFont.displayTitle)
                                    .foregroundColor(Color.textInk)
                            }
                            
                            Spacer()
                        }
                        
                        Color.secondary.frame(height: 1)
                            .padding(.horizontal, -AppLayout.spacing)
                    }
                    .padding(.horizontal, AppLayout.spacing)
                    .padding(.top, AppLayout.spacing)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    // MARK: Contents
                    LazyVStack(spacing: AppLayout.spacing) {
                        // SECTION 0: Active Orders (Primary Content)
                        if !trackingViewModel.activeOrders.isEmpty {
                            ActiveOrdersSection(orders: trackingViewModel.activeOrders) { order in
                                trackingViewModel.resumePayment(for: order)
                            }
                            Divider().hidden()
                        }
                        // AI Quick Order Prompt
                        if let cart = homeViewModel.predictedCart, !homeViewModel.isDismissedThisSession {
                            AIQuickOrderPrompt(cart: cart) {
                                withAnimation { showAIModal = true }
                            }
                            .padding(.horizontal, AppLayout.spacing)
                            Divider().hidden()
                        }
                        
                        // SECTION 1: Offers (Image-Only Banner)
                        if !homeViewModel.vouchers.isEmpty {
                            OffersSection(vouchers: homeViewModel.vouchers)
                            Divider().hidden()
                        }
                        
                        // SECTION 2: Popular Items
                        PopularSection(products: homeViewModel.popularProducts)
                        Divider().hidden()
                        
                        // SECTION 3: Events (Lighter Visual Weight)
                        if !homeViewModel.events.isEmpty {
                            EventsSection(events: homeViewModel.events)
                        }
                    }
                    .padding(.top, AppLayout.spacing)
                    .padding(.bottom, 100)
                }}
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
                .refreshable {
                    await homeViewModel.refresh()
                    await trackingViewModel.fetchActiveOrders()
                }
            }
            .blur(radius: showAIModal ? 8 : 0)
            
            // AI Quick Order Modal Overlay
            // MARK: - AI Modal
            if showAIModal, let cart = homeViewModel.predictedCart {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showAIModal = false }
                        //homeViewModel.dismissPrediction()
                    }
                
                AIQuickOrderModal(cart: cart) {
                    withAnimation {
                        showAIModal = false
                        for product in cart.items {
                            cartViewModel.addItem(product: product.product, quantity: product.quantity, customization: product.customization)
                        }
                    }
                    
                    //homeViewModel.acceptPrediction()
                } onDismiss: {
                    withAnimation { showAIModal = false }
                    //homeViewModel.dismissPrediction()
                }
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .padding(.horizontal, AppLayout.spacing)
            }
        }
        .onAppear {
            Task {
                if let user = authViewModel.currentUser {
                    trackingViewModel.setUserId(user.id)
                }
                async let homeLoad: () = homeViewModel.load()
                async let menuLoad: () = menuViewModel.load()
                _ = await (homeLoad, menuLoad)
            }
        }
        // Ensure we catch the user if they load slightly after appear
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
    }
}

// MARK: - Section 0: Active Orders

struct ActiveOrdersSection: View {
    let orders: [Order]
    var onResumePayment: (Order) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            Text(LocalizedStringKey("Your Orders (\(orders.count))"))
                .textCase(.uppercase)
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
                .padding(.horizontal, AppLayout.spacing)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: AppLayout.spacing) {
                ForEach(orders) { order in
                    OrderTrackingCard(order: order) {
                        onResumePayment(order)
                    }
                }
            }
            //.padding(.horizontal, AppLayout.spacing)
        }
    }
}

// MARK: - AI Components

struct AIQuickOrderPrompt: View {
    let cart: PredictedCart
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppLayout.spacing) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.primaryEspresso)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("For you"))
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.primaryEspresso)
                    
                    Text(cart.reason.displayText)
                        .font(AppFont.headline)
                        .foregroundStyle(Color.textInk)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textMuted)
            }
            .padding(AppLayout.spacing)
            .background(Color.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(Color.primaryEspresso, lineWidth: 1)
            )
        }
    }
}

struct AIQuickOrderModal: View {
    let cart: PredictedCart
    let onOrder: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Recommended"))
                    .font(AppFont.uiCaption)
                    .foregroundStyle(Color.primaryEspresso)
                
                Text(cart.reason.displayText)
                    .font(AppFont.sectionHeader)
                    .foregroundStyle(Color.textInk)
            }
            .padding(AppLayout.spacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceCard)
            
            Color.secondary.frame(height: 1)
            
            // Items
            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                ForEach(cart.items) { item in
                    HStack(alignment: .top, spacing: AppLayout.spacing) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.product.name)
                                .font(AppFont.body)
                                .foregroundColor(Color.textInk)

                            Text(item.customization.displayText)
                                .font(AppFont.uiCaption)
                                .foregroundColor(Color.textMuted)
                        }

                        Spacer()

                        Text(item.totalPrice.formattedVND)
                            .font(AppFont.monoBody)
                            .foregroundColor(Color.primaryEspresso)
                    }
                }

                Divider()

                HStack {
                    Text(LocalizedStringKey("Total"))
                        .font(AppFont.headline)
                        .foregroundColor(Color.textInk)
                    Spacer()
                    Text(cart.totalPrice.formattedVND)
                        .font(AppFont.monoHeadline)
                        .foregroundColor(Color.primaryEspresso)
                }
            }
            .padding(AppLayout.spacing)
            .background(Color.backgroundPaper)
            
            Color.secondary.frame(height: 1)
            
            // Actions
            HStack(spacing: 1) {
                Button(action: onDismiss) {
                    Text(LocalizedStringKey("Not now"))
                        .font(AppFont.body)
                        .foregroundStyle(Color.textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.surfaceCard)
                }
                
                Button(action: onOrder) {
                    Text(LocalizedStringKey("Order"))
                        .font(AppFont.monoHeadline)
                        .foregroundStyle(Color.backgroundPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primaryEspresso)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Section 1: Offers (Image-Only Banner)

struct OffersSection: View {
    let vouchers: [Voucher]
    @State private var selectedVoucher: Voucher?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            Text(LocalizedStringKey("Offers"))
                .textCase(.uppercase)
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
                .padding(.horizontal, AppLayout.spacing)
                .frame(maxWidth: .infinity, alignment: .leading)
            TabView {
                ForEach(vouchers) { voucher in
                    Button {
                        selectedVoucher = voucher
                    } label: {
                        CachedAsyncImage(url: URL(string: voucher.imageUrl ?? "")) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "#E8DCC8"),
                                                Color(hex: "#D4C4AA")
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay {
                                        ProgressView()
                                            .tint(Color.primaryEspresso)
                                    }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.surfaceCard)
                                    .overlay {
                                        VStack(spacing: AppLayout.spacingSmall) {
                                            Image(systemName: "ticket.fill")
                                                .font(.system(size: 32))
                                                .foregroundStyle(Color.primaryEspresso.opacity(0.3))
                                            Text(voucher.displayTitle)
                                                .font(AppFont.uiCaption)
                                                .foregroundStyle(Color.textMuted)
                                        }
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .aspectRatio(2/1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.border, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, AppLayout.spacing)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .aspectRatio(2/1, contentMode: .fit)
            .padding(.vertical, -AppLayout.spacing/2) // Add spacing for page indicator
        }
        .sheet(item: $selectedVoucher) { voucher in
            VoucherRedemptionSheet(voucher: voucher)
        }
    }
}

// MARK: - Section 2: Popular (CheckoutView Hierarchy)

struct PopularSection: View {
    let products: [PopularProduct]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            Text(LocalizedStringKey("Popular drinks"))
                .textCase(.uppercase)
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
                .padding(.horizontal, AppLayout.spacing)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                ForEach(Array(products.prefix(5).enumerated()), id: \.element.id) { index, product in
                    PopularProductCard(
                        product: product,
                        showDivider: index < min(products.count, 5) - 1
                    )
                }
            }
            .padding(.horizontal, AppLayout.spacing)
        }
    }
}

/// Product card reusing CheckoutView hierarchy
/// Shows only MEDIUM size, price is informational (not highlighted)
struct PopularProductCard: View {
    let product: PopularProduct
    var showDivider: Bool = true
    @EnvironmentObject var cartViewModel: CartViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppLayout.spacingMedium) {
                // Square Product Image (increased padding from image to text)
                // CHANGED: Using CachedAsyncImage
                CachedAsyncImage(url: URL(string: product.product.displayImageUrl ?? "")) { phase in // CHANGED
                    switch phase { // CHANGED
                    case .empty: // CHANGED
                        Rectangle() // CHANGED
                            .fill(Color.surfaceCard) // CHANGED
                            .overlay { // CHANGED
                                ProgressView() // CHANGED
                                    .tint(Color.primaryEspresso) // CHANGED
                            } // CHANGED
                    case .success(let image): // CHANGED
                        image // CHANGED
                            .resizable() // CHANGED
                            .aspectRatio(contentMode: .fill) // CHANGED
                    case .failure: // CHANGED
                        Rectangle() // CHANGED
                            .fill(Color.textInk.opacity(0.1)) // CHANGED
                            .overlay { // CHANGED
                                Image(systemName: "photo") // CHANGED
                                    .font(AppFont.productTitle) // CHANGED
                                    .foregroundStyle(Color.textInk.opacity(0.3)) // CHANGED
                            } // CHANGED
                    @unknown default: // CHANGED
                        EmptyView() // CHANGED
                    } // CHANGED
                } // CHANGED
                .frame(width: AppLayout.productImageSize, height: AppLayout.productImageSize)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                
                // Text Block (heavier, more grounded)
                VStack(alignment: .leading, spacing: AppLayout.spacing) {
                    // Product Name - Primary Visual Anchor
                    Text(product.product.name)
                        .font(AppFont.productTitle)
                        .lineLimit(2)
                        .foregroundColor(Color.textInk)
                    
                    // Spacer(minLength: AppLayout.spacingCompact)
                    
                    // Meta Row: Size + Price (MEDIUM only, informational)
                    HStack(spacing: AppLayout.spacingSmall) {
                        Text(product.product.price(for: .medium).toVND())
                            .font(AppFont.monoBody)
                            .foregroundColor(Color.textMuted.opacity(0.8))
                    }
                }
                .padding(.vertical, AppLayout.spacingCompact)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Add Button
                Button {
                    cartViewModel.addItem(product: product.product, quantity: 1, customization: .default)
                } label: {
                    Image(systemName: "plus")
                        .font(AppFont.body)
                        .padding(AppLayout.spacingMicro)
                        .foregroundStyle(Color.backgroundPaper)
                        .background(Color.primaryEspresso)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                }
            }
            if showDivider {
                Divider()
                    .padding(.vertical, AppLayout.spacing)
            }
        }
    }
}

// MARK: - Section 3: Events (Lighter Visual Weight)

struct EventsSection: View {
    let events: [Event]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            // Lighter section header
            Text(LocalizedStringKey("Upcoming events"))
                .textCase(.uppercase)
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
                .padding(.horizontal, AppLayout.spacing)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Horizontal scroll, editorial tone
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.spacingMedium) {
                    ForEach(events) { event in
                        EventCard(event: event)
                    }
                }
                .padding(.horizontal, AppLayout.spacing)
            }
        }
    }
}

struct EventCard: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image (Square)
            // CHANGED: Using CachedAsyncImage
            if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { phase in // CHANGED
                    switch phase { // CHANGED
                    case .empty: // CHANGED
                        Rectangle() // CHANGED
                            .fill(Color.surfaceCard) // CHANGED
                            .overlay { // CHANGED
                                ProgressView() // CHANGED
                                    .tint(Color.primaryEspresso) // CHANGED
                            } // CHANGED
                    case .success(let image): // CHANGED
                        image // CHANGED
                            .resizable() // CHANGED
                            .aspectRatio(contentMode: .fill) // CHANGED
                    case .failure: // CHANGED
                        Rectangle() // CHANGED
                            .fill(Color.surfaceCard) // CHANGED
                    @unknown default: // CHANGED
                        EmptyView() // CHANGED
                    } // CHANGED
                } // CHANGED
                .frame(width: 200, height: 200) // Fixed width, square aspect ratio
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                .overlay {
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(Color.border.opacity(0.3), lineWidth: 1)
                }
            } else {
                Rectangle()
                    .fill(Color.surfaceCard)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
            
            // Text content - minimal, editorial
            VStack(alignment: .leading, spacing: AppLayout.spacingSmall) {
                // Title (Product Title Font)
                Text(event.title)
                    .font(AppFont.productTitle)
                    .foregroundColor(Color.textInk)
                    .lineLimit(1)
                
                // Meta Row: EVENT · Subtitle
                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(AppFont.monoCaption)
                        .tracking(1.0)
                        .foregroundColor(Color.textInk.opacity(0.6))
                        .textCase(.uppercase)
                }
            }
            .padding(.top, AppLayout.spacingMedium)
            .padding(.bottom, AppLayout.spacingCompact)
            .frame(width: 200, alignment: .leading)
            // Removed background(Color.surfaceCard)
        }
        // Removed outer clipShape and overlay/border
    }
}
