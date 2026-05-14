//
//  PromotionsView.swift
//

import SwiftUI

private enum PromotionBarcodeFocusTarget: Equatable {
    case member
    case voucher(String)
}

struct PromotionsView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var networkService: NetworkService

    @State private var showLogin = false
    @State private var focusedBarcode: PromotionBarcodeFocusTarget = .member

    var body: some View {
        ZStack {
            BaseViewColor.background.ignoresSafeArea()

            if authViewModel.isAuthenticated {
                GeometryReader { proxy in
                    let layout = PromotionSvgLayout(containerWidth: proxy.size.width)

                    ScrollView(.vertical, showsIndicators: false) {
                    authenticatedContent(layout: layout)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .refreshable { await profileViewModel.manualRefresh() }
                }
            } else {
                guestContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .fullScreenCover(isPresented: $showLogin) { LoginView() }
        .onAppear {
            if authViewModel.isAuthenticated {
                profileViewModel.loadProfile()
                Task { await profileViewModel.distributeAndRefreshVouchers() }
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { ok in
            if ok {
                showLogin = false
                profileViewModel.loadProfile()
                Task { await profileViewModel.distributeAndRefreshVouchers() }
            }
        }
    }

    private var barcodePreloadKey: String {
        profileViewModel.vouchers
            .filter(\.isValid)
            .map(\.id)
            .sorted()
            .joined(separator: ",")
    }

    // MARK: - Authenticated

    private func authenticatedContent(layout: PromotionSvgLayout) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Name
            Text(profileViewModel.userProfile?.fullName ?? "Member")
                .font(BaseViewFont.screenTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(.horizontal, PromotionSvgMetric.horizontalInset)
                .padding(.top, layout.nameTopPadding)

            // Tier + points (same row, center-aligned)
            HStack(alignment: .center) {
                Text(profileViewModel.userProfile?.membershipTier.displayName ?? "Bronze")
                    .font(BaseViewFont.screenSubtitle)
                    .foregroundStyle(BaseViewColor.textPrimary)
                Spacer()
                BaseAccentBadge(title: "POINTS: \(profileViewModel.userProfile?.points ?? 0)")
            }
            .padding(.horizontal, PromotionSvgMetric.horizontalInset)
            .padding(.top, layout.tierTopPadding)
            .padding(.bottom, layout.headerBottomPadding)
            let memberId = profileViewModel.userProfile?.shortId ?? "------"
            VStack(spacing: layout.memberIdSpacing) {
                PromotionBarcodePanel(
                    payload: "u:\(memberId)",
                    isFocused: focusedBarcode == .member,
                    placeholderText: "BẤM ĐỂ HIỆN MÃ",
                    panelHeight: layout.memberPanelHeight,
                    contentInsets: EdgeInsets(
                        top: layout.memberBarcodeVerticalInset,
                        leading: PromotionSvgMetric.barcodeHorizontalInset,
                        bottom: layout.memberBarcodeVerticalInset,
                        trailing: PromotionSvgMetric.barcodeHorizontalInset
                    ),
                    backgroundColor: .white,
                    borderColor: Color(hex: "#979797"),
                    lineWidth: PromotionSvgMetric.pointsBadgeStrokeWidth,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            focusedBarcode = .member
                        }
                    }
                )
                Text("Mã thành viên: \(memberId)")
                    .font(BaseViewFont.screenSubtitle)
                    .foregroundStyle(BaseViewColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PromotionSvgMetric.horizontalInset)
            .padding(.bottom, layout.vouchersFromIdBottom)

            // Vouchers header
            HStack(alignment: .firstTextBaseline) {
                Text("Vouchers")
                    .font(BaseViewFont.sectionTitle)
                    .foregroundStyle(BaseViewColor.textPrimary)
                Spacer()
                Text("\(profileViewModel.vouchers.count)")
                    .font(BaseViewFont.screenSubtitle)
                    .foregroundStyle(BaseViewColor.textPrimary)
            }
            .padding(.horizontal, PromotionSvgMetric.horizontalInset)
            .padding(.bottom, layout.vouchersHeaderPaddingBottom)

            // Voucher rows
            voucherList(layout: layout)
        }
    }

    // MARK: - Voucher list (Apple Wallet stack)

    private func voucherList(layout: PromotionSvgLayout) -> some View {
        let valid = profileViewModel.vouchers.filter { $0.isValid }
        let invalid = profileViewModel.vouchers.filter { !$0.isValid }
        let sorted = valid + invalid
        guard !sorted.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(spacing: 0) {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, voucher in
                    PassCard(
                        voucher: voucher,
                        layout: layout,
                        isFocused: focusedBarcode == .voucher(voucher.id),
                        topSpacing: index == 0 ? 0 : PromotionSvgMetric.voucherListSpacing,
                        expiryDate: voucher.validUntil.map {
                            $0.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.defaultDigits))
                        } ?? "–",
                        action: { focusVoucherBarcode(for: voucher) }
                    )
                }
            }
            .padding(.horizontal, PromotionSvgMetric.horizontalInset)
            .padding(.bottom, layout.stackBottomPadding)
        )
    }

    private func focusVoucherBarcode(for voucher: Voucher) {
        guard voucher.isValid else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            focusedBarcode = .voucher(voucher.id)
        }
    }

    // MARK: - Guest

    private var guestContent: some View {
        AppAuthPromptCard(
            title: "Đăng nhập để sử dụng tính năng này",
            message: "Tham gia hội viên để nhận được điểm, phần thưởng\nvà nhiều ưu đãi khác.",
            actionTitle: "ĐĂNG NHẬP HOẶC THAM GIA"
        ) {
            showLogin = true
        }
    }
}

// MARK: - PassCard — exact match to SVG row (116x116 left block)

private struct PassCard: View {
    let voucher: Voucher
    let layout: PromotionSvgLayout
    let isFocused: Bool
    let topSpacing: CGFloat
    let expiryDate: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Use only first 8 chars of UUID for an ultra-short barcode
                PromotionBarcodePanel(
                    payload: String(voucher.id.prefix(8)).uppercased(),
                    isFocused: isFocused,
                    placeholderText: voucher.isValid ? "BẤM ĐỂ HIỆN MÃ" : "HẾT HẠN",
                    panelHeight: layout.cardHeaderHeight,
                    contentInsets: EdgeInsets(
                        top: layout.voucherBarcodeVerticalInset,
                        leading: PromotionSvgMetric.voucherBarcodeHorizontalInset,
                        bottom: layout.voucherBarcodeVerticalInset,
                        trailing: PromotionSvgMetric.voucherBarcodeHorizontalInset
                    ),
                    backgroundColor: .white,
                    borderColor: Color(hex: "#979797"),
                    lineWidth: PromotionSvgMetric.strokeWidth,
                    isLoading: false,
                    errorText: nil,
                    action: action
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(voucher.displayTitle)
                        .font(BaseViewFont.cardTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .lineLimit(2)

                    Text(voucher.code)
                        .font(BaseViewFont.label)
                        .foregroundStyle(BaseViewColor.textSecondary)

                    Text("Hết hạn: \(expiryDate)")
                        .font(BaseViewFont.label)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, layout.cardContentHPad)
                .padding(.top, layout.cardContentTopPad)
                .padding(.bottom, layout.cardContentBottomPad)
                .background(Color.white)
            }
            .background(Color.white)
            .overlay(Rectangle().stroke(Color(hex: "#979797"), lineWidth: PromotionSvgMetric.strokeWidth))
            .opacity(voucher.isValid ? 1.0 : 0.45)
            .frame(minHeight: layout.cardHeight, alignment: .top)
        }
        .padding(.top, topSpacing)
    }
}

private struct PromotionBarcodePanel: View {
    let payload: String?
    let isFocused: Bool
    let placeholderText: String
    let panelHeight: CGFloat
    let contentInsets: EdgeInsets
    let backgroundColor: Color
    let borderColor: Color
    let lineWidth: CGFloat
    var isLoading: Bool = false
    var errorText: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GeometryReader { proxy in
                let innerWidth = max(proxy.size.width - contentInsets.leading - contentInsets.trailing, 0)
                let innerHeight = max(min(proxy.size.height - contentInsets.top - contentInsets.bottom, innerWidth / PromotionSvgMetric.barcodeAspectRatio), 0)

                ZStack {
                    backgroundColor

                    if let payload {
                        BarcodeRenderView(payload: payload)
                            .frame(width: innerWidth, height: innerHeight)
                            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                            .blur(radius: isFocused ? 0 : PromotionSvgMetric.inactiveBlurRadius)
                    } else if isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        RoundedRectangle(cornerRadius: 0, style: .continuous)
                            .fill(Color.black.opacity(0.04))
                            .frame(width: innerWidth, height: innerHeight)
                            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    }

                    if !isFocused {
                        BaseAccentBadge(title: errorText ?? placeholderText)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: panelHeight)
        .overlay(Rectangle().stroke(borderColor, lineWidth: lineWidth))
    }
}

private struct PromotionSvgLayout {
    let contentWidth: CGFloat

    init(containerWidth: CGFloat) {
        self.contentWidth = max(containerWidth - (PromotionSvgMetric.horizontalInset * 2), 0)
    }

    private var scale: CGFloat {
        contentWidth / PromotionSvgMetric.referenceContentWidth
    }

    var nameTopPadding: CGFloat { 23 * scale }
    var tierTopPadding: CGFloat { 6 * scale }
    var headerBottomPadding: CGFloat { 23 * scale }
    var memberPanelHeight: CGFloat { 92 * scale }
    var memberBarcodeVerticalInset: CGFloat { 5 * scale }
    var memberIdSpacing: CGFloat { 19 * scale }
    var vouchersFromIdBottom: CGFloat { 40 * scale }
    var vouchersHeaderPaddingBottom: CGFloat { 23 * scale }
    var voucherBarcodeVerticalInset: CGFloat { 7 * scale }
    var cardHeight: CGFloat { 160 * scale }
    var cardHeaderHeight: CGFloat { 93 * scale }
    var cardContentHPad: CGFloat { 13 * scale }
    var cardContentTopPad: CGFloat { 13 * scale }
    var cardContentBottomPad: CGFloat { 13 * scale }
    var stackBottomPadding: CGFloat { 32 * scale }
}

// MARK: - Metrics

private enum PromotionSvgMetric {
    static let horizontalInset: CGFloat = 23
    static let referenceContentWidth: CGFloat = 356
    static let voucherListSpacing: CGFloat = 13
    static let barcodeAspectRatio: CGFloat = 4
    static let barcodeHorizontalInset: CGFloat = 13
    static let voucherBarcodeHorizontalInset: CGFloat = 13
    static let pointsBadgeStrokeWidth: CGFloat = 1
    static let inactiveBlurRadius: CGFloat = 8
    static let strokeWidth: CGFloat = 1
}

