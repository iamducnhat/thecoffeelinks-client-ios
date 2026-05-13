import SwiftUI
import UIKit

struct MenuView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var menuViewModel: MenuViewModel
    @EnvironmentObject private var cartViewModel: CartViewModel
    @EnvironmentObject private var storesViewModel: StoresViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedProduct: Product?
    @State private var unavailableProductID: String?
    @State private var currentSectionIndex: Int = 0
    @State private var barTriggerCount: Int = 0
    @State private var shouldFocusSearch: Bool = false
    @State private var hasScrolledToFirst: Bool = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    OverscrollDetector {
                        shouldFocusSearch = true
                    }
                    .frame(height: 0)
                    searchField
                        .padding(.top, MenuSvgMetric.topSpacing)
                        .padding(.horizontal, BaseViewLayout.screenInset)

                    separator
                        .padding(.top, MenuSvgMetric.searchToDividerGap)

                    content
                }
                .padding(.bottom, cartViewModel.isEmpty ? MenuSvgMetric.bottomPadding : MenuSvgMetric.bottomPaddingWithCart)
            }
            .background(BaseViewColor.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .coordinateSpace(name: "menuScroll")
            .onPreferenceChange(SectionYKey.self) { updateVisibleSection($0) }
            .onChange(of: shouldFocusSearch) { triggered in
                guard triggered else { return }
                isSearchFocused = true
                shouldFocusSearch = false
            }
            .onAppear {
                barTriggerCount += 1
                if !displaySections.isEmpty, !hasScrolledToFirst {
                    hasScrolledToFirst = true
                    DispatchQueue.main.async {
                        proxy.scrollTo(displaySections[0].id, anchor: .top)
                    }
                }
            }
            .onChange(of: displaySections.count) { count in
                guard count > 0, !hasScrolledToFirst else { return }
                hasScrolledToFirst = true
                proxy.scrollTo(displaySections[0].id, anchor: .top)
            }
            .overlay(alignment: .trailing) {
                if !displaySections.isEmpty {
                    CategoryScrollBar(
                        sections: displaySections,
                        onSelectSection: { section in
                            proxy.scrollTo(section.id, anchor: .top)
                        },
                        triggerCount: barTriggerCount,
                        triggerIndex: currentSectionIndex
                    )
                    .ignoresSafeArea(.keyboard)
                }
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailSheet(product: product)
            }
            .task(id: storesViewModel.selectedStore?.id) {
                await menuViewModel.load(storeId: storesViewModel.selectedStore?.id)
            }
        }
    }

    private var searchField: some View {
        TextField(
            "",
            text: $menuViewModel.searchQuery,
            prompt: Text("Tìm kiếm")
                .font(BaseViewFont.body)
                .foregroundColor(Color.textSecondary.opacity(0.8))
        )
        .font(BaseViewFont.body)
        .foregroundStyle(Color.textPrimary)
        .focused($isSearchFocused)
        .submitLabel(.search)
        .onSubmit { isSearchFocused = false }
        .padding(.horizontal, BaseViewLayout.badgeInset)
        .frame(height: MenuSvgMetric.searchHeight)
        .frame(maxWidth: .infinity)
        .background(searchFieldBackground)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Huỷ") {
                    menuViewModel.clearSearch()
                    isSearchFocused = false
                }
                .font(BaseViewFont.labelStrong)
                .foregroundStyle(BaseViewColor.accent)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if menuViewModel.isLoading && displaySections.isEmpty {
            ProgressView()
                .tint(Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, MenuSvgMetric.loadingTopPadding)
        } else if displaySections.isEmpty {
            emptyState
                .padding(.horizontal, BaseViewLayout.screenInset)
                .padding(.top, MenuSvgMetric.emptyStateTopPadding)
        } else {
            ForEach(Array(displaySections.enumerated()), id: \.element.id) { index, section in
                MenuCategorySection(
                    title: section.title,
                    products: section.products,
                    showsTopDivider: index > 0,
                    unavailableProductID: unavailableProductID,
                    onSelectProduct: handleProductTap,
                    onGoToStores: goToStores
                )
                .id(section.id)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: SectionYKey.self,
                            value: [section.id: geo.frame(in: .named("menuScroll")).minY]
                        )
                    }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: MenuSvgMetric.emptyStateSpacing) {
            Text(searchQuery.isEmpty ? "MENU ĐANG ĐƯỢC CẬP NHẬT" : "KHÔNG TÌM THẤY MÓN PHÙ HỢP")
                .font(BaseViewFont.sectionTitle)
                .foregroundStyle(BaseViewColor.textPrimary)

            Text(searchQuery.isEmpty ? "Vui lòng kéo xuống để tải lại danh sách món." : "Thử một từ khoá khác để xem thêm kết quả.")
                .font(BaseViewFont.label)
                .foregroundStyle(BaseViewColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(Color.borderPrimary.opacity(0.75))
            .frame(height: MenuSvgMetric.separatorThickness)
    }

    private var searchFieldBackground: Color {
        colorScheme == .dark
            ? Color.textPrimary.opacity(0.12)
            : Color.textPrimary.opacity(0.08)
    }

    private var searchQuery: String {
        menuViewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displaySections: [MenuDisplaySection] {
        if !searchQuery.isEmpty {
            return groupedSections(from: combinedSearchResults)
        }

        let filteredProducts = menuViewModel.filteredProducts
        let knownCategoryIDs = Set(menuViewModel.categories.map(\.id))

        var sections = menuViewModel.categories.compactMap { category -> MenuDisplaySection? in
            let products = filteredProducts.filter { $0.categoryId == category.id }
            guard !products.isEmpty else { return nil }
            return MenuDisplaySection(id: category.id, title: category.displayName, products: products)
        }

        let uncategorizedProducts = filteredProducts.filter { !knownCategoryIDs.contains($0.categoryId) }
        if !uncategorizedProducts.isEmpty {
            sections.append(MenuDisplaySection(id: "uncategorized", title: "Khác", products: uncategorizedProducts))
        }

        return sections
    }

    private var combinedSearchResults: [Product] {
        var orderedProducts: [Product] = []
        var seenProductIDs = Set<String>()

        let localMatches = menuViewModel.filteredProducts.filter { matchesSearch($0) }
        let remoteMatches = menuViewModel.searchResults.filter { isVisibleProduct($0) }

        for product in localMatches + remoteMatches where seenProductIDs.insert(product.id).inserted {
            orderedProducts.append(product)
        }

        return orderedProducts
    }

    private func groupedSections(from products: [Product]) -> [MenuDisplaySection] {
        guard !products.isEmpty else { return [] }

        let groupedProducts = Dictionary(grouping: products, by: \.categoryId)
        let orderedCategoryIDs = menuViewModel.categories.map(\.id)
        let knownCategoryIDs = Set(orderedCategoryIDs)

        var sections = orderedCategoryIDs.compactMap { categoryID -> MenuDisplaySection? in
            guard let category = menuViewModel.categories.first(where: { $0.id == categoryID }),
                  let sectionProducts = groupedProducts[categoryID],
                  !sectionProducts.isEmpty else {
                return nil
            }

            return MenuDisplaySection(id: categoryID, title: category.displayName, products: sectionProducts)
        }

        let unknownProducts = products.filter { !knownCategoryIDs.contains($0.categoryId) }
        if !unknownProducts.isEmpty {
            sections.append(MenuDisplaySection(id: "search-unknown", title: "Khác", products: unknownProducts))
        }

        return sections
    }

    private func matchesSearch(_ product: Product) -> Bool {
        product.name.localizedCaseInsensitiveContains(searchQuery) ||
        product.description?.localizedCaseInsensitiveContains(searchQuery) == true
    }

    private func isVisibleProduct(_ product: Product) -> Bool {
        guard product.isActive else { return false }
        if menuViewModel.orderingMode == .delivery || menuViewModel.showDeliverableOnly {
            return product.canBeDelivered
        }
        return true
    }

    private func updateVisibleSection(_ positions: [String: CGFloat]) {
        let sections = displaySections
        guard !sections.isEmpty else { return }
        // Section at top = largest minY that is still ≤ threshold
        let threshold: CGFloat = 120
        var bestId: String? = nil
        var bestY: CGFloat = -CGFloat.infinity
        for (id, y) in positions where y <= threshold {
            if y > bestY {
                bestY = y
                bestId = id
            }
        }
        if let id = bestId,
           let idx = sections.firstIndex(where: { $0.id == id }) {
            currentSectionIndex = idx
        }
    }

    private func handleProductTap(_ product: Product) {
        if product.effectiveAvailability {
            selectedProduct = product
            return
        }

        unavailableProductID = product.id

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if unavailableProductID == product.id {
                unavailableProductID = nil
            }
        }
    }

    private func goToStores() {
        unavailableProductID = nil
        appState.selectedTab = 2
    }
}

private struct MenuCategorySection: View {
    let title: String
    let products: [Product]
    let showsTopDivider: Bool
    let unavailableProductID: String?
    let onSelectProduct: (Product) -> Void
    let onGoToStores: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsTopDivider {
                Rectangle()
                    .fill(BaseViewColor.border)
                    .frame(height: MenuSvgMetric.separatorThickness)
            }

            Text(title.uppercased())
                .font(BaseViewFont.sectionTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(.top, MenuSvgMetric.sectionTopPadding)
                .padding(.bottom, MenuSvgMetric.sectionTitleBottomPadding)
                .padding(.horizontal, BaseViewLayout.screenInset)

            VStack(spacing: MenuSvgMetric.cardSpacing) {
                ForEach(products) { product in
                    MenuProductCard(
                        product: product,
                        showsUnavailableOverlay: unavailableProductID == product.id,
                        onTap: { onSelectProduct(product) },
                        onGoToStores: onGoToStores
                    )
                }
            }
            .padding(.horizontal, BaseViewLayout.screenInset)
            .padding(.bottom, MenuSvgMetric.sectionBottomPadding)
        }
    }
}

private struct MenuProductCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let product: Product
    let showsUnavailableOverlay: Bool
    let onTap: () -> Void
    let onGoToStores: () -> Void

    private let unavailableOverlayBackground = BaseViewColor.placeholder

    var body: some View {
        GeometryReader { geometry in
            let imageWidth = geometry.size.height

            ZStack {
                HStack(spacing: 0) {
                    productImage
                        .frame(width: imageWidth, height: geometry.size.height)

                    VStack(alignment: .leading, spacing: 0) {
                        TwoLineText(
                            text: product.name.uppercased(),
                            font: BaseViewFont.cardTitle,
                            color: BaseViewColor.textPrimary,
                            height: MenuSvgMetric.productTitleTwoLineHeight
                        )
                        .lineSpacing(MenuSvgMetric.productTitleLineSpacing)

                        Spacer(minLength: 0)

                        HStack(alignment: .bottom, spacing: MenuSvgMetric.inlineContentSpacing) {
                            Text(displayPrice)
                                .font(BaseViewFont.label)
                                .foregroundStyle(BaseViewColor.textSecondary)

                            Spacer(minLength: 0)

                            Text("MUA NGAY")
                                .font(BaseViewFont.labelStrong)
                                .tracking(2)
                                .underline()
                                .foregroundStyle(BaseViewColor.textPrimary)
                        }
                    }
                    .padding(.leading, MenuSvgMetric.contentInset)
                    .padding(.trailing, MenuSvgMetric.contentInset)
                    .padding(.vertical, MenuSvgMetric.cardVerticalInset)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(BaseViewColor.background)
                .opacity(product.effectiveAvailability ? 1 : 0.4)

                if showsUnavailableOverlay {
                    unavailableOverlay
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .overlay(
                Rectangle()
                    .stroke(BaseViewColor.border, lineWidth: MenuSvgMetric.separatorThickness)
            )
            .clipShape(Rectangle())
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
        .aspectRatio(MenuSvgMetric.cardAspectRatio, contentMode: .fit)
    }

    private var unavailableOverlay: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Hiện tại món này đã hết, vui lòng chọn món hoặc cửa hàng khác.")
                .font(BaseViewFont.cardTitle.weight(.regular))
                .foregroundStyle(BaseViewColor.textPrimary)
                .lineSpacing(MenuSvgMetric.productTitleLineSpacing)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onGoToStores) {
                Text("Đi đến trang chọn cửa hàng")
                    .font(BaseViewFont.labelStrong)
                    .tracking(2)
                    .foregroundStyle(BaseViewColor.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(MenuSvgMetric.contentInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(unavailableOverlayBackground)
    }

    private var productImage: some View {
        AppRemoteImage(
            url: URL(string: product.displayImageUrl ?? ""),
            source: .native,
            contentMode: .fill,
            cornerRadius: 0,
            backgroundColor: placeholderFill,
            placeholderIcon: nil
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var placeholderFill: Color {
        colorScheme == .dark
            ? Color.textPrimary.opacity(0.16)
            : Color.textPrimary.opacity(0.14)
    }

    private var displayPrice: String {
        if let mediumPrice = product.sizeOptions.first(where: { $0.size == .medium })?.price {
            return mediumPrice.formattedVND
        }
        return product.basePrice.formattedVND
    }
}

// MARK: - Overscroll Detector

private struct OverscrollDetector: UIViewRepresentable {
    let onOverscroll: () -> Void
    private let threshold: CGFloat = 100

    func makeCoordinator() -> Coordinator { Coordinator(threshold: threshold, onOverscroll: onOverscroll) }

    @MainActor
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.detach()
    }

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.backgroundColor = .clear
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onOverscroll = onOverscroll
        DispatchQueue.main.async {
            if let sv = uiView.firstParentScrollView() {
                context.coordinator.attach(to: sv)
            }
        }
    }

    final class Coordinator: NSObject {
        let threshold: CGFloat
        var onOverscroll: () -> Void
        private var observation: NSKeyValueObservation?
        private weak var attachedScrollView: UIScrollView?
        private var hasTriggered = false

        init(threshold: CGFloat, onOverscroll: @escaping () -> Void) {
            self.threshold = threshold
            self.onOverscroll = onOverscroll
        }

        func attach(to scrollView: UIScrollView) {
            guard observation == nil else { return }
            attachedScrollView = scrollView
            debugPrint("[OverscrollDetector] attached to \(scrollView)")
            scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
            observation = scrollView.observe(\.contentOffset, options: .new) { [weak self] _, change in
                guard let self, let y = change.newValue?.y else { return }
                if y < -self.threshold {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.hasTriggered = true
                        debugPrint("[OverscrollDetector] armed at y=\(y)")
                    }
                }
            }
        }

        @MainActor
        func detach() {
            observation?.invalidate()
            observation = nil
            attachedScrollView?.panGestureRecognizer.removeTarget(self, action: #selector(handlePan(_:)))
            attachedScrollView = nil
            hasTriggered = false
        }

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard gesture.state == .ended || gesture.state == .cancelled else { return }
            guard hasTriggered else { return }
            hasTriggered = false
            debugPrint("[OverscrollDetector] FIRE — finger lifted after overscroll")
            onOverscroll()
        }

        deinit {
            observation?.invalidate()
        }
    }
}

private extension UIView {
    func firstParentScrollView() -> UIScrollView? {
        var view: UIView? = superview
        while let v = view {
            if let sv = v as? UIScrollView { return sv }
            view = v.superview
        }
        return nil
    }
}

// MARK: - Category Scroll Bar

private struct TopOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct SectionYKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct CategoryScrollBar: View {
    let sections: [MenuDisplaySection]
    let onSelectSection: (MenuDisplaySection) -> Void
    let triggerCount: Int
    let triggerIndex: Int

    @State private var activeIndex: Int? = nil
    @State private var showLabel: Bool = false
    @State private var hideTask: DispatchWorkItem? = nil
    @State private var cachedSegH: CGFloat = 0
    @State private var cachedPitch: CGFloat = 0

    private let barWidth: CGFloat = 10
    private let touchWidth: CGFloat = 33
    private let segmentGap: CGFloat = 2
    private let labelHeight: CGFloat = 22
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        GeometryReader { geo in
            let count = sections.count
            if count > 0 {
                ZStack(alignment: .topTrailing) {
                    Color.clear
                        .onAppear { recompute(height: geo.size.height, count: count) }
                        .onChange(of: geo.size.height) { recompute(height: $0, count: count) }
                        .onChange(of: triggerCount) { _ in
                            guard !sections.isEmpty else { return }
                            let idx = min(triggerIndex, sections.count - 1)
                            activeIndex = idx
                            hideTask?.cancel()
                            withAnimation(.easeIn(duration: 0.12)) { showLabel = true }
                            scheduleHide()
                        }

                    // Floating category label
                    if showLabel, let idx = activeIndex, idx < count, cachedSegH > 0 {
                        let midY = CGFloat(idx) * cachedPitch + cachedSegH / 2
                        Text(sections[idx].title.uppercased())
                            .font(BaseViewFont.labelStrong)
                            .tracking(2)
                            .foregroundStyle(BaseViewColor.accentForeground)
                            .lineLimit(1)
                            .padding(4)
                            .background(BaseViewColor.accent)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(.trailing, barWidth + 5)
                            .padding(.top, max(0, midY - labelHeight / 2))
                            .allowsHitTesting(false)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.15), value: showLabel)
                    }

                    // Segment rectangles + touch target
                    VStack(spacing: segmentGap) {
                        ForEach(Array(sections.enumerated()), id: \.element.id) { idx, _ in
                            Rectangle()
                                .fill(
                                    activeIndex == idx
                                        ? BaseViewColor.accent
                                        : BaseViewColor.accent.opacity(0.25)
                                )
                                .frame(width: barWidth, height: cachedSegH > 0 ? cachedSegH : 4)
                        }
                    }
                    .frame(width: touchWidth, alignment: .trailing)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard cachedPitch > 0 else { return }
                                let idx = min(count - 1, max(0, Int(value.location.y / cachedPitch)))
                                if idx != activeIndex {
                                    activeIndex = idx
                                    haptic.impactOccurred()
                                    onSelectSection(sections[idx])
                                }
                                hideTask?.cancel()
                                if !showLabel {
                                    withAnimation(.easeIn(duration: 0.12)) { showLabel = true }
                                }
                            }
                            .onEnded { _ in scheduleHide() }
                    )
                }
            }
        }
    }

    private func recompute(height: CGFloat, count: Int) {
        guard count > 0, height > 0 else { return }
        let totalGap = segmentGap * CGFloat(count - 1)
        let h = max(4, (height - totalGap) / CGFloat(count))
        cachedSegH = h
        cachedPitch = h + segmentGap
        haptic.prepare()
    }

    private func scheduleHide() {
        let task = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.25)) {
                showLabel = false
            }
        }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: task)
    }
}

// MARK: - Menu Display Section

private struct MenuDisplaySection: Identifiable {
    let id: String
    let title: String
    let products: [Product]
}

private enum MenuSvgMetric {
    static let horizontalInset: CGFloat = 23
    static let topSpacing: CGFloat = 26
    static let searchHeight: CGFloat = 49
    static let searchInnerPadding: CGFloat = 13
    static let searchToDividerGap: CGFloat = 23
    static let sectionTopPadding: CGFloat = 24
    static let sectionTitleBottomPadding: CGFloat = 19
    static let sectionBottomPadding: CGFloat = 23
    static let cardSpacing: CGFloat = 13
    static let contentInset: CGFloat = 13
    static let cardVerticalInset: CGFloat = 9
    static let productTitleLineHeight: CGFloat = 23
    static let productTitleLineSpacing: CGFloat = 5
    static let productTitleTwoLineHeight: CGFloat = productTitleLineHeight * 2
    static let inlineContentSpacing: CGFloat = 12
    static let separatorThickness: CGFloat = 0.5
    static let loadingTopPadding: CGFloat = 48
    static let emptyStateTopPadding: CGFloat = 48
    static let emptyStateSpacing: CGFloat = 10
    static let bottomPadding: CGFloat = 32
    static let bottomPaddingWithCart: CGFloat = 116
    static let cardAspectRatio: CGFloat = 356 / 116
}


#Preview {
    NavigationStack {
        MenuView()
            .environmentObject(DependencyContainer.shared.makeMenuViewModel())
            .environmentObject(DependencyContainer.shared.makeCartViewModel())
    }
}
