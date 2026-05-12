//
//  MenuComponents.swift
//  thecoffeelinks-client-ios
//

import SwiftUI

struct ProductDetailSheet: View {
    let product: Product
    var cartItem: CartItem? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var cartViewModel: CartViewModel
    @EnvironmentObject private var menuViewModel: MenuViewModel
    @ScaledMetric(relativeTo: .body) private var ctaButtonVerticalPadding: CGFloat = 10
    @ScaledMetric(relativeTo: .body) private var ctaButtonHorizontalPadding: CGFloat = 16

    @State private var quantity = 1
    @State private var selectedSize: ProductSize = .medium
    @State private var selectedToppings: Set<String> = []
    @State private var notes: String = ""
    @State private var sugarLevel: SugarLevel = .half
    @State private var iceLevel: IceLevel = .normal

    private enum SVG {
        static let horizontalInset: CGFloat = 23

        static let metadataHeight: CGFloat = 227
        static let sugarHeight: CGFloat = 109
        static let iceHeight: CGFloat = 224
        static let toppingsHeight: CGFloat = 188
        static let notesHeight: CGFloat = 230

        static let gapAfterDivider: CGFloat = 23
        static let gapTitleToContent: CGFloat = 28
        static let gapBetweenRows: CGFloat = 13

        static let metadataTitleToDescriptionGap: CGFloat = 10

        static let listRowHeight: CGFloat = 23
        static let listRowTopInset: CGFloat = 3.5

        static let notesBottomGap: CGFloat = 46
        static let notesBoxHeight: CGFloat = 114

        static let titleSize: CGFloat = 22
        static let titleTwoLineHeight: CGFloat = 56
        static let bodySize: CGFloat = 18
        static let bodyLineSpacing: CGFloat = 5

        static let ctaTopInset: CGFloat = 23
        static let ctaLabelToPriceGap: CGFloat = 13
        static let ctaPriceToButtonGap: CGFloat = 13
        static let ctaPriceTopInset: CGFloat = 41
        static let ctaQuantityTopInset: CGFloat = 43
        static let ctaButtonTopInset: CGFloat = 82
        static let qtyControlHeight: CGFloat = 23
        static let qtyControlGap: CGFloat = 8
        static let qtyValueWidth: CGFloat = 36
        static let ctaBottomInset: CGFloat = 25
    }

    private let dividerColor = BaseViewColor.border
    private let secondaryTextColor = BaseViewColor.textSecondary
    private let notesBg = Color(hex: "727272").opacity(0.08)
    private let heroPlaceholder = BaseViewColor.placeholder
    private let sheetBackground = BaseViewColor.background

    init(product: Product, cartItem: CartItem? = nil) {
        self.product = product
        self.cartItem = cartItem

        if let item = cartItem {
            _quantity = State(initialValue: item.quantity)
            _selectedSize = State(initialValue: item.customization.size)
            _selectedToppings = State(initialValue: Set(item.customization.toppings.map { $0.id }))
            _notes = State(initialValue: item.customization.notes ?? "")
            _sugarLevel = State(initialValue: item.customization.sugar ?? .half)
            _iceLevel = State(initialValue: item.customization.ice ?? .normal)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sheetBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ctaOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(sheetBackground.ignoresSafeArea())
    }

    private var hero: some View {
        Rectangle()
            .fill(heroPlaceholder)
            .overlay {
                if let imageUrl = product.displayImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    BaseUnderlinedCTA(title: "HUỶ BỎ")
                        .padding(4)
                        .background(sheetBackground)
                }
                .buttonStyle(.plain)
                .padding(.top, SVG.horizontalInset)
                .padding(.trailing, SVG.horizontalInset)
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipped()
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            metadataSection
            sectionDivider
            sugarSection
            sectionDivider
            iceSection
            sectionDivider
            toppingsSection
            sectionDivider
            notesSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sheetBackground)
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: SVG.metadataTitleToDescriptionGap) {
            TwoLineText(
                text: product.name.uppercased(),
                font: BaseViewFont.sectionTitle,
                color: BaseViewColor.textPrimary,
                height: SVG.titleTwoLineHeight
            )

            if let description = product.description, !description.isEmpty {
                Text(description)
                    .font(BaseViewFont.body)
                    .lineSpacing(SVG.bodyLineSpacing)
                    .foregroundStyle(BaseViewColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, SVG.horizontalInset)
        .padding(.top, SVG.gapAfterDivider)
        .padding(.bottom, SVG.gapAfterDivider)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var sugarSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Đường")
                .font(BaseViewFont.bodyStrong)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(.bottom, SVG.gapTitleToContent)

            ExactSugarSlider(selection: $sugarLevel)
                .frame(maxWidth: .infinity)
                .frame(height: 16)
        }
        .padding(.horizontal, SVG.horizontalInset)
        .padding(.top, SVG.gapAfterDivider)
        .padding(.bottom, SVG.gapAfterDivider)
        .frame(maxWidth: .infinity, minHeight: SVG.sugarHeight, alignment: .topLeading)
    }

    private var iceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Đá")
                .font(BaseViewFont.bodyStrong)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(.bottom, SVG.gapTitleToContent)

            VStack(alignment: .leading, spacing: SVG.gapBetweenRows) {
                ForEach(iceOptions, id: \.self) { level in
                    Button {
                        iceLevel = level
                    } label: {
                        ZStack(alignment: .topLeading) {
                            HStack(spacing: 12) {
                                AppTickbox(isSelected: iceLevel == level, size: 16)

                                Text(level.displayName)
                                    .font(BaseViewFont.body)
                                    .foregroundStyle(iceLevel == level ? BaseViewColor.textPrimary : secondaryTextColor)
                            }
                            .padding(.top, SVG.listRowTopInset)
                        }
                        .frame(height: SVG.listRowHeight, alignment: .topLeading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .background(sheetBackground)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, SVG.horizontalInset)
        .padding(.top, SVG.gapAfterDivider)
        .padding(.bottom, SVG.gapAfterDivider)
        .frame(maxWidth: .infinity, minHeight: SVG.iceHeight, alignment: .topLeading)
    }

    private var toppingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Đi kèm")
                .font(BaseViewFont.bodyStrong)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(.bottom, SVG.gapTitleToContent)

            VStack(alignment: .leading, spacing: SVG.gapBetweenRows) {
                ForEach(availableToppings.prefix(3), id: \.id) { topping in
                    Button {
                        if selectedToppings.contains(topping.id) {
                            selectedToppings.remove(topping.id)
                        } else {
                            selectedToppings.insert(topping.id)
                        }
                    } label: {
                        ZStack(alignment: .topLeading) {
                            HStack(spacing: 12) {
                                AppCheckbox(isSelected: selectedToppings.contains(topping.id), size: 16)

                                Text(topping.name)
                                    .font(BaseViewFont.body)
                                    .foregroundStyle(selectedToppings.contains(topping.id) ? BaseViewColor.textPrimary : secondaryTextColor)

                                Spacer()

                                Text(topping.price.formattedVND)
                                    .font(BaseViewFont.body)
                                    .foregroundStyle(selectedToppings.contains(topping.id) ? BaseViewColor.textPrimary : secondaryTextColor)
                            }
                            .padding(.top, SVG.listRowTopInset)
                        }
                        .frame(height: SVG.listRowHeight, alignment: .topLeading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .background(sheetBackground)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, SVG.horizontalInset)
        .padding(.top, SVG.gapAfterDivider)
        .padding(.bottom, SVG.gapAfterDivider)
        .frame(maxWidth: .infinity, minHeight: SVG.toppingsHeight, alignment: .topLeading)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Lưu ý cho món")
                .font(BaseViewFont.bodyStrong)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(.bottom, SVG.gapTitleToContent)

            ZStack(alignment: .topLeading) {
                Rectangle().fill(notesBg)
                if notes.isEmpty {
                    Text("Bấm để nhập...")
                        .font(BaseViewFont.body)
                        .foregroundStyle(secondaryTextColor)
                        .padding(.top, 12)
                        .padding(.leading, 6)
                }
                TextEditor(text: $notes)
                    .font(BaseViewFont.body)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: SVG.notesBoxHeight)
        }
        .padding(.horizontal, SVG.horizontalInset)
        .padding(.top, SVG.gapAfterDivider)
        .padding(.bottom, SVG.notesBottomGap)
        .frame(maxWidth: .infinity, minHeight: SVG.notesHeight, alignment: .topLeading)
    }

    private var ctaOverlay: some View {
        VStack(alignment: .leading, spacing: 0) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: SVG.ctaLabelToPriceGap) {
                    Text("\(quantity) sản phẩm")
                        .font(BaseViewFont.labelStrong)
                        .foregroundStyle(secondaryTextColor)

                    Text((unitPrice * Double(quantity)).formattedVND)
                        .font(BaseViewFont.sectionTitle)
                        .foregroundStyle(Color.textPrimary)

                    Text("Số lượng")
                        .font(BaseViewFont.labelStrong)
                        .foregroundStyle(secondaryTextColor)

                    quantityPicker
                }
                .padding(.bottom, SVG.ctaPriceToButtonGap)
            } else {
                ZStack(alignment: .topLeading) {
                    HStack(alignment: .top) {
                        Text("\(quantity) sản phẩm")
                            .font(BaseViewFont.labelStrong)
                            .foregroundStyle(secondaryTextColor)

                        Spacer()

                        Text("Số lượng")
                            .font(BaseViewFont.labelStrong)
                            .foregroundStyle(secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    Text((unitPrice * Double(quantity)).formattedVND)
                        .font(BaseViewFont.sectionTitle)
                        .foregroundStyle(Color.textPrimary)
                        .padding(.top, SVG.ctaPriceTopInset - SVG.ctaTopInset)

                    quantityPicker
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .padding(.top, SVG.ctaQuantityTopInset - SVG.ctaTopInset)

                    ctaButton
                        .padding(.top, SVG.ctaButtonTopInset - SVG.ctaTopInset)
                }
                .padding(.bottom, SVG.ctaBottomInset)
            }

            if dynamicTypeSize.isAccessibilitySize {
                ctaButton
            }
        }
        .padding(.top, SVG.ctaTopInset)
        .padding(.horizontal, SVG.horizontalInset)
        .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? SVG.ctaBottomInset : 0)
        .background(sheetBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.textPrimary)
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ctaButton: some View {
        BaseCTAButton(title: "THÊM VÀO GIỎ HÀNG", fillsWidth: true) {
            addOrUpdateCartItem()
        }
    }

    private var quantityPicker: some View {
        HStack(spacing: SVG.qtyControlGap) {
            Button {
                quantity = max(1, quantity - 1)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(BaseViewColor.accentForeground)
                    .frame(width: SVG.qtyControlHeight, height: SVG.qtyControlHeight)
                    .background(BaseViewColor.accent.opacity(0.7))
            }
            .buttonStyle(.plain)

            ZStack {
                Text("9999")
                    .font(BaseViewFont.body)
                    .hidden()
                Text("\(quantity)")
                    .font(BaseViewFont.body)
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(minWidth: SVG.qtyValueWidth)
            .frame(height: SVG.qtyControlHeight)
            .overlay(
                Rectangle().stroke(BaseViewColor.border, lineWidth: 1)
            )

            Button {
                quantity = min(9999, quantity + 1)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(BaseViewColor.accentForeground)
                    .frame(width: SVG.qtyControlHeight, height: SVG.qtyControlHeight)
                    .background(BaseViewColor.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private var unitPrice: Double {
        let toppingTotal = menuViewModel.toppings
            .filter { selectedToppings.contains($0.id) }
            .reduce(0) { $0 + $1.price }
        return product.price(for: selectedSize) + toppingTotal
    }

    private func addOrUpdateCartItem() {
        let toppingSelections = menuViewModel.toppings
            .filter { selectedToppings.contains($0.id) }
            .map { ToppingSelection(id: $0.id, name: $0.name, price: $0.price, quantity: 1) }

        let customization = OrderCustomization(
            size: selectedSize,
            sugar: sugarLevel,
            ice: iceLevel,
            toppings: toppingSelections,
            notes: notes.isEmpty ? nil : notes
        )

        if let existingItem = cartItem {
            cartViewModel.updateItem(id: existingItem.id, quantity: quantity, customization: customization)
        } else {
            cartViewModel.addItem(product: product, quantity: quantity, customization: customization)
        }
        dismiss()
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 0.5)
            .frame(maxWidth: .infinity)
    }

    private var iceOptions: [IceLevel] {
        [.normal, .less, .extra, .none]
    }

    private var availableToppings: [Topping] {
        product.availableToppings.compactMap { toppingId in
            menuViewModel.toppings.first(where: { $0.id == toppingId && $0.isAvailable })
        }
    }
}

private struct ExactSugarSlider: View {
    @Binding var selection: SugarLevel

    private let levels = SugarLevel.allCases
    private let markerSize: CGFloat = 16
    private let visualHeight: CGFloat = 16
    private let hitPaddingY: CGFloat = 14
    private let markerCenterY: CGFloat = 8
    private let trackHeight: CGFloat = 2
    private let trackY: CGFloat = 7

    var body: some View {
        GeometryReader { geo in
            let halfMarker = markerSize / 2
            let usableWidth = max(0, geo.size.width - markerSize)
            let step = usableWidth / CGFloat(max(1, levels.count - 1))

            let centers: [CGFloat] = (0..<levels.count).map { index in
                halfMarker + (CGFloat(index) * step)
            }
            let selectedCenter = centers[selectedIndex]
            let dragGesture = DragGesture(minimumDistance: 0)
                .onChanged { value in
                    updateSelection(for: value.location.x, in: geo.size.width, step: step, halfMarker: halfMarker)
                }

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(BaseViewColor.border)
                    .frame(width: max(0, selectedCenter - halfMarker), height: trackHeight)
                    .offset(x: halfMarker, y: trackY)

                Rectangle()
                    .fill(BaseViewColor.border)
                    .frame(width: max(0, geo.size.width - selectedCenter), height: trackHeight)
                    .offset(x: selectedCenter, y: trackY)

                ForEach(0..<levels.count, id: \.self) { i in
                    AppTickbox(isSelected: i <= selectedIndex, size: markerSize)
                    .position(x: centers[i], y: markerCenterY)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.vertical, hitPaddingY)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .padding(.vertical, -hitPaddingY)
        }
        .frame(height: visualHeight)
    }

    private var selectedIndex: Int {
        levels.firstIndex(of: selection) ?? 0
    }

    private func updateSelection(for x: CGFloat, in width: CGFloat, step: CGFloat, halfMarker: CGFloat) {
        let clampedX = min(max(x, halfMarker), width - halfMarker)
        let rawIndex = Int(round((clampedX - halfMarker) / max(step, 1)))
        let index = min(max(rawIndex, 0), levels.count - 1)
        selection = levels[index]
    }
}

