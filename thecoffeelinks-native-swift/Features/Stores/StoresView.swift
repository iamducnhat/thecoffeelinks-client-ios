//
//  StoresView.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import CachedAsyncImage // CHANGED

struct StoresView: View {
    @EnvironmentObject var viewModel: StoresViewModel
    @State private var selectedStore: Store?
    @State private var viewMode: StoreViewMode = .list
    @State private var scrollOffset = CGFloat.zero
    
    enum StoreViewMode: String, CaseIterable {
        case list = "List"
        case map = "Map"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            ScrollView(.vertical) { LazyVStack(alignment: .leading, spacing: AppLayout.spacing) {
                // Header
                VStack(alignment: .leading, spacing: AppLayout.spacing) {
                    Text("Find a Store")
                        .font(AppFont.displayTitle)
                        .foregroundColor(Color.textInk)
                        .padding(.top, AppLayout.spacing)
                    
                    // Search
                    HStack(spacing: AppLayout.spacingMedium) {
                        Image(systemName: "magnifyingglass")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                        
                        TextField("Search by name or address...", text: $viewModel.searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(AppFont.body)
                            .foregroundStyle(Color.textInk)
                        
                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                    }
                    
                    // View Mode Toggle
                    HStack(spacing: 0) {
                        ForEach(StoreViewMode.allCases, id: \.self) { mode in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewMode = mode
                                }
                            } label: {
                                Text(mode.rawValue.uppercased())
                                    .font(AppFont.monoBody)
                                    .foregroundStyle(viewMode == mode ? Color.backgroundPaper : Color.textMuted)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(viewMode == mode ? Color.textInk : Color.clear)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(Color.textInk, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                    
                    Color.secondary.frame(height: 1)
                        .padding(.horizontal, -AppLayout.spacing)
                }
                .padding(.horizontal, AppLayout.spacing)
                .background(GeometryReader {
                    Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                })
                .onPreferenceChange(ViewOffsetKey.self) {
                    self.scrollOffset = $0
                }
                
                // Content
                if !viewModel.filteredStores.isEmpty {
                    switch viewMode {
                    case .list:
                        StoreListContent(
                            stores: viewModel.filteredStores,
                            viewModel: viewModel,
                            selectedStore: $selectedStore
                        )
                    case .map:
                        StoreMapView(
                            stores: viewModel.filteredStores,
                            selectedStore: $selectedStore
                        )
                        .frame(height: 400)
                        .padding(.horizontal, AppLayout.spacing)
                    }
                } else if viewModel.isLoading {
                    // Initial load (no cache) - Show clean state (no skeleton)
                    // Alternatively, show a minimal "Locating..." text if desired, but requirements say "no loading indicators"
                    // We will render nothing until content arrives, or EmptyStoreState if it finishes empty.
                    // To avoid looking broken, we might want a simple spacer.
                    Spacer().frame(height: 200)
                } else {
                    EmptyStoresState()
                }
            }}
            .coordinateSpace(name: "scroll")
            .scrollIndicators(.hidden)
        }
        .fullScreenCover(item: $selectedStore) { store in
            StoreDetailView(store: store, viewModel: viewModel)
        }
        .onAppear {
            Task { await viewModel.load() }
        }
    }
}

// MARK: - Store List Content

struct StoreListContent: View {
    let stores: [Store]
    let viewModel: StoresViewModel
    @Binding var selectedStore: Store?
    
    var body: some View {
        LazyVStack(spacing: AppLayout.spacing) {
            ForEach(stores) { store in
                StoreCard(store: store, viewModel: viewModel)
                    .onTapGesture {
                        selectedStore = store
                    }
            }
        }
        .padding(.horizontal, AppLayout.spacing)
        .padding(.bottom, 100)
    }
}

// MARK: - Store Card

struct StoreCard: View {
    let store: Store
    let viewModel: StoresViewModel
    @State private var distance: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Store Image
            // CHANGED: Using CachedAsyncImage
            CachedAsyncImage(url: URL(string: store.imageUrl ?? "")) { phase in // CHANGED
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
                        .overlay { // CHANGED
                            Text(String(store.name.prefix(1))) // CHANGED
                                .font(AppFont.displayTitle) // CHANGED
                                .foregroundStyle(Color.textMuted) // CHANGED
                        } // CHANGED
                @unknown default: // CHANGED
                    EmptyView() // CHANGED
                } // CHANGED
            } // CHANGED
            .frame(height: 160)
            .clipped()
            
            // Store Info
            VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
                Text(store.name)
                    .font(AppFont.headline)
                    .foregroundStyle(Color.textInk)
                
                Text(store.address)
                    .font(AppFont.uiCaption)
                    .foregroundStyle(Color.textMuted)
                    .lineLimit(2)
                
                // Status Row
                HStack(spacing: AppLayout.spacingMedium) {
                    // Distance
                    if let distance = distance {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                            Text(distance)
                                .font(AppFont.monoBody)
                        }
                        .foregroundStyle(Color.textMuted)
                    }
                    
                    // Open/Closed Status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(store.isCurrentlyOpen ? Color.semanticSuccess : Color.semanticError)
                            .frame(width: 6, height: 6)
                        Text(store.isCurrentlyOpen ? "Open" : "Closed")
                            .font(AppFont.monoBody)
                            .foregroundStyle(store.isCurrentlyOpen ? Color.semanticSuccess : Color.semanticError)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textMuted)
                }
            }
            .padding(AppLayout.spacing)
            .background(Color.surfaceCard)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        .task {
            distance = await viewModel.getDistance(to: store)
        }
    }
}

// MARK: - Skeleton

struct StoreListSkeleton: View {
    var body: some View {
        LazyVStack(spacing: AppLayout.spacing) {
            ForEach(0..<4, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(Color.surfaceCard)
                        .frame(height: 160)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Rectangle().fill(Color.border).frame(height: 16)
                        Rectangle().fill(Color.border).frame(width: 200, height: 12)
                        Rectangle().fill(Color.border).frame(width: 100, height: 12)
                    }
                    .padding(AppLayout.spacing)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(Color.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
        }
        .padding(.horizontal, AppLayout.spacing)
    }
}

// MARK: - Empty State

struct EmptyStoresState: View {
    var body: some View {
        VStack(spacing: AppLayout.spacingXL) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color.textMuted)
            
            Text("No stores found")
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
            
            Text("Try adjusting your search or check back later.")
                .font(AppFont.body)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(60)
    }
}
