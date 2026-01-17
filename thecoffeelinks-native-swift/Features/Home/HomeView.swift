//
//  HomeView.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    
    @State private var showAIModal = false
    @State private var scrollOffset = CGFloat.zero
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // MARK: Header
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hello, \(authViewModel.currentUser?.displayName ?? "GUEST")")
                                    .font(AppFont.uiCaption)
                                    .foregroundStyle(Color.primaryEspresso)
                                
                                Text("The Coffee Links")
                                    .font(AppFont.displayTitle)
                                    .foregroundColor(Color.textInk)
                            }
                            
                            Spacer()
                            
                            // Delivery Toggle
//                            Button {
//                                withAnimation { appState.isDeliveryMode.toggle() }
//                            } label: {
//                                HStack(spacing: 8) {
//                                    Image(systemName: appState.isDeliveryMode ? "bicycle" : "cup.and.saucer")
//                                        .font(AppFont.monoCaption)
//                                    Text(appState.isDeliveryMode ? "delivery" : "dine-in")
//                                        .textCase(.uppercase)
//                                        .font(AppFont.monoBody)
//                                }
//                                .padding(AppLayout.spacingMicro)
//                                .foregroundStyle(appState.isDeliveryMode ? Color.backgroundPaper : Color.textInk)
//                                .background(appState.isDeliveryMode ? Color.textInk : Color.backgroundPaper)
//                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
//                                        .stroke(Color.textInk, lineWidth: appState.isDeliveryMode ? 0 : 1)
//                                )
//                            }
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
                    
                    LazyVStack(spacing: AppLayout.spacingXL) {
                        // AI Quick Order Prompt
                        if let cart = homeViewModel.predictedCart, !homeViewModel.isDismissedThisSession {
                            AIQuickOrderPrompt(cart: cart) {
                                withAnimation { showAIModal = true }
                            }
                            .padding(.horizontal, AppLayout.spacing)
                        }
                        
                        // Hero Section (Events)
                        if !homeViewModel.events.isEmpty {
                            EventsSection(events: homeViewModel.events)
                        }
                        
                        // Categories
                        CategoriesSection(categories: menuViewModel.categories)
                        
                        // Popular Products
                        PopularSection(products: homeViewModel.popularProducts)
                    }
                    .padding(.top, AppLayout.spacing)
                    .padding(.bottom, 100)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
                .refreshable {
                    await homeViewModel.refresh()
                }
            }
            .blur(radius: showAIModal ? 8 : 0)
            
            // AI Quick Order Modal Overlay
            if showAIModal, let cart = homeViewModel.predictedCart {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showAIModal = false }
                        homeViewModel.dismissPrediction()
                    }
                
                AIQuickOrderModal(cart: cart) {
                    withAnimation { showAIModal = false }
                    homeViewModel.acceptPrediction()
                } onDismiss: {
                    withAnimation { showAIModal = false }
                    homeViewModel.dismissPrediction()
                }
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .padding(.horizontal, AppLayout.spacing)
            }
        }
        .onAppear {
            Task {
                async let homeLoad: () = homeViewModel.load()
                async let menuLoad: () = menuViewModel.load()
                _ = await (homeLoad, menuLoad)
            }
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
                    Text("For you")
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.primaryEspresso)
                    
                    Text(cart.reason.displayText ?? "Resume your ritual?")
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
                Text("Recommended")
                    .font(AppFont.uiCaption)
                    .foregroundStyle(Color.primaryEspresso)
                
                Text(cart.reason.displayText ?? "Intelligence Prediction")
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
                    HStack {
                        Text(item.product.name)
                            .font(AppFont.body)
                            .foregroundColor(Color.textInk)
                        Spacer()
                        Text(item.product.price.formattedCurrency)
                            .font(AppFont.monoBody)
                            .foregroundColor(Color.primaryEspresso)
                    }
                }
            }
            .padding(AppLayout.spacing)
            .background(Color.backgroundPaper)
            
            Color.secondary.frame(height: 1)
            
            // Actions
            HStack(spacing: 1) {
                Button(action: onDismiss) {
                    Text("Not now")
                        .font(AppFont.body)
                        .foregroundStyle(Color.textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.surfaceCard)
                }
                
                Button(action: onOrder) {
                    Text("Order")
                        .font(AppFont.monoCTA)
                        .foregroundStyle(Color.backgroundPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.accentColor)
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

// MARK: - Events Section

struct EventsSection: View {
    let events: [Event]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            HStack {
                Text("Upcoming events")
                    .textCase(.uppercase)
                    .font(AppFont.sectionHeader)
                    .foregroundStyle(Color.textInk)
                Spacer(minLength: AppLayout.spacing)
                Color.secondary.frame(height: 1)
            }
            .padding(.horizontal, AppLayout.spacing)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.spacing) {
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
            // Image
            ZStack(alignment: .bottomLeading) {
                if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color.surfaceCard
                        }
                    }
                    .frame(width: 300, height: 200)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(Color.surfaceCard)
                        .frame(width: 300, height: 200)
                }
                
                Text(event.subtitle ?? "DATA")
                    .font(AppFont.uiMicro.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryEspresso)
                    .foregroundStyle(Color.backgroundPaper)
                    .padding(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(AppFont.headline)
                    .foregroundColor(Color.textInk)
                    .lineLimit(2)
            }
            .padding(AppLayout.spacing)
            .frame(width: 300, alignment: .leading)
            .background(Color.surfaceCard)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Categories Section

struct CategoriesSection: View {
    let categories: [Category]
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            Text("Our categories")
                .textCase(.uppercase)
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
                .padding(.horizontal, AppLayout.spacing)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.spacingMedium) {
                    ForEach(categories) { category in
                        Button {
                            menuViewModel.selectCategory(category)
                            appState.selectedTab = 1
                        } label: {
                            Text(category.displayName)
                                .font(AppFont.monoBody)
                                .foregroundColor(Color.textInk)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.backgroundPaper)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.textInk, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, AppLayout.spacing)
            }
        }
    }
}

// MARK: - Popular Section

struct PopularSection: View {
    let products: [PopularProduct]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            Text("Popular drinks")
                .textCase(.uppercase)
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
                .padding(.horizontal, AppLayout.spacing)
            
            VStack(spacing: 0) {
                ForEach(Array(products.prefix(5).enumerated()), id: \.element.id) { index, product in
                    ProductRow(
                        product: product,
                        showDivider: index < min(products.count, 5) - 1
                    )
                }
            }
            .padding(.horizontal, AppLayout.spacing)
        }
    }
}

struct ProductRow: View {
    let product: PopularProduct
    var showDivider: Bool = true
    @EnvironmentObject var cartViewModel: CartViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppLayout.spacing) {
                AsyncImage(url: URL(string: product.product.displayImageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.textInk.opacity(0.1))
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(AppLayout.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(Color.border, lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.product.name)
                        .font(AppFont.body)
                        .foregroundColor(Color.textInk)
                    
                    Text(product.product.priceRange)
                        .font(AppFont.monoBody)
                        .foregroundColor(Color.primaryEspresso)
                }
                
                Spacer()
                
                Button {
                    cartViewModel.addItem(product: product.product, quantity: 1, customization: .default)
                } label: {
                    Image(systemName: "plus")
                        .font(AppFont.body)
                        .padding(AppLayout.spacingMicro)
                        .foregroundStyle(Color.backgroundPaper)
                        .background(Color.textInk)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                }
            }
            .padding(.vertical, AppLayout.spacing)
            
            if showDivider {
                Color.secondary.frame(height: 1)
            }
        }
    }
}
