import SwiftUI

struct StoresView: View {
    @EnvironmentObject var viewModel: StoresViewModel
    @State private var selectedStore: Store?
    @State private var showMapView = false
    @State private var displayedCount: Int = 10
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            stickyHeader

            if showMapView {
                StoreMapView(stores: viewModel.filteredStores, selectedStore: $selectedStore)
            } else if viewModel.filteredStores.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                listView
            }
        }
        .background(BaseViewColor.background)
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(item: $selectedStore) { store in
            StoreDetailView(store: store, viewModel: viewModel)
        }
        .onAppear {
            Task { await viewModel.load() }
        }
    }

    // MARK: - Sticky Header

    private var stickyHeader: some View {
        VStack(spacing: 0) {
            // Row 1: Search + Map toggle
            HStack(spacing: 8) {
                TextField("", text: $viewModel.searchQuery, prompt:
                    Text("Tìm kiếm")
                        .foregroundColor(Color(.systemGray))
                )
                .textFieldStyle(PlainTextFieldStyle())
                .font(BaseViewFont.label)
                .foregroundStyle(BaseViewColor.textPrimary)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit { isSearchFocused = false }
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .frame(minHeight: BaseViewLayout.accentBadgeHeight)
                .background(BaseViewColor.textPrimary.opacity(0.08))
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Huỷ") {
                            viewModel.searchQuery = ""
                            isSearchFocused = false
                        }
                        .font(BaseViewFont.labelStrong)
                        .foregroundStyle(BaseViewColor.accent)
                    }
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showMapView.toggle() }
                } label: {
                    BaseAccentBadge(title: showMapView ? "DANH SÁCH" : "BẢN ĐỒ")
                }
                .buttonStyle(.plain)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 23)
            .padding(.top, 10)

            // Row 2: City / District filters
            HStack(spacing: 0) {
                Text("Tỉnh/Thành phố")
                    .font(BaseViewFont.label)
                    .foregroundStyle(Color(.systemGray))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 5)
                    .frame(minHeight: 26)
                    .overlay(Rectangle().stroke(Color(.systemGray3), lineWidth: 1))

                Spacer().frame(width: 8)

                Text("Quận/Huyện")
                    .font(BaseViewFont.label)
                    .foregroundStyle(Color(.systemGray))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 5)
                    .frame(minHeight: 26)
                    .overlay(Rectangle().stroke(Color(.systemGray3), lineWidth: 1))
            }
            .padding(.horizontal, 23)
            .padding(.top, 9)

            // Separator
            Rectangle()
                .fill(BaseViewColor.textPrimary.opacity(0.15))
                .frame(height: 0.5)
                .padding(.top, 13)
        }
        .padding(.bottom, 0)
        .background(BaseViewColor.background)
    }

    // MARK: - List View

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.filteredStores.prefix(displayedCount))) { store in
                    StoreListCard(store: store, viewModel: viewModel)
                    .padding(.horizontal, 23)
                    .padding(.top, 13)
                }

                // Pagination trigger
                if displayedCount < viewModel.filteredStores.count {
                    Color.clear
                        .frame(height: 1)
                        .onAppear { loadMore() }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .onChange(of: viewModel.searchQuery) { _ in
            displayedCount = 10
        }
    }

    private func loadMore() {
        displayedCount = min(displayedCount + 10, viewModel.filteredStores.count)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("KHÔNG TÌM THẤY CỬA HÀNG")
                .font(BaseViewFont.sectionTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .multilineTextAlignment(.center)

            Text("Thử điều chỉnh từ khoá tìm kiếm.")
                .font(BaseViewFont.label)
                .foregroundStyle(BaseViewColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding(24)
    }
}

// MARK: - Store List Card

private struct StoreListCard: View {
    @Environment(\.openURL) private var openURL
    let store: Store
    @ObservedObject var viewModel: StoresViewModel

    @State private var distance: String? = nil

    private let buttonRowHeight: CGFloat = 38
    private var isSelected: Bool {
        viewModel.selectedStore?.id == store.id
    }

    var body: some View {
        VStack(spacing: 0) {
            // Content area — GeometryReader drives square image (height == imageWidth)
            GeometryReader { geometry in
                let imageWidth = geometry.size.height
                HStack(spacing: 0) {
                    storeImage
                        .frame(width: imageWidth, height: geometry.size.height)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(store.name.uppercased())
                            .font(BaseViewFont.cardTitle)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 9)

                        Spacer(minLength: 4)

                        HStack(alignment: .firstTextBaseline) {
                            Text("Giờ mở cửa")
                                .font(BaseViewFont.body)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            Spacer()
                            Text(openTime ?? "--:--")
                                .font(BaseViewFont.body)
                                .foregroundStyle(BaseViewColor.textPrimary)
                        }

                        HStack(alignment: .firstTextBaseline) {
                            Text("Giờ đóng cửa")
                                .font(BaseViewFont.body)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            Spacer()
                            Text(closeTime ?? "--:--")
                                .font(BaseViewFont.body)
                                .foregroundStyle(BaseViewColor.textPrimary)
                        }
                        .padding(.bottom, 9)
                    }
                    .padding(.horizontal, 13)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
            .aspectRatio(356 / 116, contentMode: .fit)

            // Horizontal divider
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)

            // Action buttons
            HStack(spacing: 0) {
                Button(action: openDirections) {
                    Text("CHỈ ĐƯỜNG")
                        .font(BaseViewFont.labelStrong)
                        .tracking(2)
                        .foregroundStyle(BaseViewColor.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .frame(minHeight: buttonRowHeight)
                }

                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 0.5, height: buttonRowHeight)

                Button(action: selectStore) {
                    Text(isSelected ? "ĐÃ CHỌN" : "CHỌN")
                        .font(BaseViewFont.labelStrong)
                        .tracking(2)
                        .foregroundStyle(isSelected ? BaseViewColor.accent : BaseViewColor.accentForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .frame(minHeight: buttonRowHeight)
                        .background(isSelected ? Color.clear : BaseViewColor.accent)
                }
                .buttonStyle(.plain)
                .disabled(isSelected)
            }
        }
        .overlay(Rectangle().stroke(Color(.systemGray4), lineWidth: 0.5))
        .task {
            distance = await viewModel.getDistance(to: store)
        }
    }

    private var storeImage: some View {
        AppRemoteImage(
            url: URL(string: store.imageUrl ?? ""),
            source: .native,
            contentMode: .fill,
            cornerRadius: 0,
            placeholderIcon: nil
        ) {
            if let dist = distance {
                Text(dist)
                    .font(BaseViewFont.labelStrong)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.regularMaterial)
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var openTime: String? {
        todayHours?.openTime
    }

    private var closeTime: String? {
        todayHours?.closeTime
    }

    private var todayHours: OpeningHour? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return store.openingHours?.first(where: { $0.dayOfWeek == weekday })
    }

    private func openDirections() {
        let lat = store.latitude
        let lng = store.longitude
        let name = store.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?ll=\(lat),\(lng)&q=\(name)") {
            openURL(url)
        }
    }

    private func selectStore() {
        guard !isSelected else { return }
        viewModel.selectStore(store)
    }
}

// MARK: - Store Card (used in StoreSelectionSheet and other contexts)

struct StoreCard: View {
    let store: Store
    let viewModel: StoresViewModel

    var body: some View {
        AppStoreCard(
            title: store.name,
            address: store.address,
            imageURL: URL(string: store.imageUrl ?? ""),
            variant: .simple
        )
    }
}

// MARK: - Preview

#Preview {
    StoresView()
        .environmentObject(DependencyContainer.shared.makeStoresViewModel())
}
