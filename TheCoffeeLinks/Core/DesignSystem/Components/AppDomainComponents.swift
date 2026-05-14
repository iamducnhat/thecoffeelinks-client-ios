import SwiftUI

struct AppProductCard: View {
    let title: String
    let price: String
    var imageURL: URL? = nil
    var badgeText: String? = nil
    var actionTitle: String? = nil
    var width: CGFloat? = nil
    var imageAspectRatio: CGFloat = 1
    var onTap: (() -> Void)? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            AppRemoteImage(
                url: imageURL,
                source: .native,
                width: width,
                height: imageHeight,
                aspectRatio: width == nil ? imageAspectRatio : nil,
                cornerRadius: 0,
                placeholderIcon: nil
            ) {
                if !price.isEmpty {
                    Text(price)
                        .font(BaseViewFont.labelStrong)
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .background(BaseViewColor.elevatedSurface)
                        .padding(.leading, BaseViewLayout.badgeInset)
                        .padding(.bottom, BaseViewLayout.badgeInset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                TwoLineText(
                    text: title.uppercased(),
                    font: BaseViewFont.cardTitle,
                    color: BaseViewColor.textPrimary,
                    height: BaseViewLayout.cardTitleTwoLineHeight
                )

                if let badgeText {
                    Spacer().frame(height: 10)
                    AppBadge(text: badgeText, style: .neutral)
                }

                if let actionTitle, let onAction {
                    Spacer().frame(height: 24)
                    AppButton(actionTitle, style: .underlined, fillsWidth: false, action: onAction)
                } else if let actionTitle {
                    Spacer().frame(height: 24)
                    Text(actionTitle)
                        .font(BaseViewFont.cta)
                        .tracking(2)
                        .underline()
                        .foregroundStyle(BaseViewColor.textPrimary)
                }
            }
            .padding(.leading, BaseViewLayout.contentInset)
            .padding(.top, BaseViewLayout.contentInset)
            .padding(.bottom, BaseViewLayout.contentInset)
            .frame(width: width, alignment: .topLeading)
        }
        .frame(width: width, alignment: .topLeading)
        .overlay(
            Rectangle()
                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
        .contentShape(Rectangle())
    }

    private var imageHeight: CGFloat? {
        guard let width else { return nil }
        return width / max(imageAspectRatio, 0.001)
    }
}

struct AppProductRow: View {
    let title: String
    let price: String
    var subtitle: String? = nil
    var imageURL: URL? = nil
    var quantity: Int? = nil
    var onDecrease: (() -> Void)? = nil
    var onIncrease: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack(spacing: BaseViewLayout.spacingMedium) {
            AppRemoteImage(
                url: imageURL,
                width: BaseViewLayout.productImageSize,
                height: BaseViewLayout.productImageSize
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BaseViewFont.headline)
                    .foregroundStyle(BaseViewColor.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(BaseViewFont.uiCaption)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }

                Spacer(minLength: BaseViewLayout.spacing)

                HStack(spacing: 0) {
                    Text(price)
                        .font(BaseViewFont.monoBody)
                        .foregroundStyle(BaseViewColor.accent)

                    Spacer(minLength: 0)

                    if let quantity, let onDecrease, let onIncrease {
                        AppQuantityStepper(quantity: quantity, onDecrease: onDecrease, onIncrease: onIncrease)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct AppStoreCard: View {
    enum Variant {
        case rich
        case simple
        case compact
    }

    let title: String
    let address: String
    var statusText: String? = nil
    var distanceText: String? = nil
    var imageURL: URL? = nil
    var isSelected: Bool = false
    var variant: Variant = .simple
    var primaryActionTitle: String? = nil
    var secondaryActionTitle: String? = nil
    var onPrimaryAction: (() -> Void)? = nil
    var onSecondaryAction: (() -> Void)? = nil

    var body: some View {
        switch variant {
        case .rich:
            richContent
        case .simple, .compact:
            simpleContent
        }
    }

    private var simpleContent: some View {
        HStack(spacing: BaseViewLayout.spacing) {
            if variant != .compact {
                AppRemoteImage(
                    url: imageURL,
                    source: .native,
                    width: 56,
                    height: 56,
                    cornerRadius: BaseViewLayout.radiusMedium,
                    placeholderIcon: nil
                )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(BaseViewFont.labelStrong)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .lineLimit(2)

                Text(address)
                    .font(BaseViewFont.label)
                    .foregroundStyle(BaseViewColor.textSecondary)
                    .lineLimit(variant == .compact ? 1 : 2)

                if let statusText {
                    Text(statusText)
                        .font(BaseViewFont.label)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
            }

            Spacer()

            if isSelected {
                IconView(name: "circle_check")
                    .font(.system(size: 20))
                    .foregroundStyle(BaseViewColor.accent)
            } else {
                IconView(name: "chevron_right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BaseViewColor.textSecondary)
            }
        }
        .padding(BaseViewLayout.spacing)
        .background(BaseViewColor.elevatedSurface)
        .overlay(
            RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                .strokeBorder(isSelected ? BaseViewColor.accent : BaseViewColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
    }

    private var richContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                AppRemoteImage(
                    url: imageURL,
                    source: .native,
                    width: 116,
                    height: 116,
                    cornerRadius: 0,
                    placeholderIcon: nil
                ) {
                    if let distanceText {
                        Text(distanceText)
                            .font(BaseViewFont.labelStrong)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.regularMaterial)
                            .padding(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(title.uppercased())
                        .font(BaseViewFont.cardTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .lineLimit(2)

                    Text(address)
                        .font(BaseViewFont.body)
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .lineLimit(2)

                    if let statusText {
                        Text(statusText)
                            .font(BaseViewFont.label)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                if let secondaryActionTitle, let onSecondaryAction {
                    Button(action: onSecondaryAction) {
                        Text(secondaryActionTitle)
                            .font(BaseViewFont.labelStrong)
                            .tracking(2)
                            .foregroundStyle(BaseViewColor.accent)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppDomainActionMetric.horizontalPadding)
                            .padding(.vertical, AppDomainActionMetric.verticalPadding)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: AppDomainActionMetric.minHeight)
                    }
                    .buttonStyle(.plain)
                }

                if primaryActionTitle != nil && secondaryActionTitle != nil {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 0.5)
                        .frame(maxHeight: .infinity)
                }

                if let primaryActionTitle, let onPrimaryAction {
                    Button(action: onPrimaryAction) {
                        Text(primaryActionTitle)
                            .font(BaseViewFont.labelStrong)
                            .tracking(2)
                            .foregroundStyle(isSelected ? BaseViewColor.accent : BaseViewColor.accentForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppDomainActionMetric.horizontalPadding)
                            .padding(.vertical, AppDomainActionMetric.verticalPadding)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: AppDomainActionMetric.minHeight)
                            .background(isSelected ? Color.clear : BaseViewColor.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSelected)
                }
            }
        }
        .overlay(Rectangle().stroke(Color(.systemGray4), lineWidth: 0.5))
    }
}

private enum AppDomainActionMetric {
    static let minHeight: CGFloat = 38
    static let horizontalPadding: CGFloat = 13
    static let verticalPadding: CGFloat = 10
}

struct AppVoucherPassCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var statusText: String? = nil
    var accentColor: Color = Color(red: 0.18, green: 0.52, blue: 0.36)
    var actionTitle: String? = nil
    var isMuted: Bool = false
    let action: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                accentColor
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(.white.opacity(0.22))
            }
            .frame(width: 116)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.custom("GeologicaThinRoman-Medium", size: 18))
                    .foregroundStyle(BaseViewColor.textPrimary)

                Text(value)
                    .font(BaseViewFont.monoHeadline)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .padding(.top, 2)

                Spacer()

                Divider()
                    .padding(.bottom, 6)

                HStack(alignment: .bottom) {
                    if let subtitle {
                        Text(subtitle)
                            .font(BaseViewFont.uiMicro)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    } else if let statusText {
                        Text(statusText)
                            .font(BaseViewFont.uiMicro)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    }

                    Spacer()

                    if let actionTitle, let action {
                        Button(action: action) {
                            Text(actionTitle)
                                .font(BaseViewFont.uiMicro)
                                .fontWeight(.semibold)
                                .kerning(2)
                                .underline()
                                .foregroundStyle(BaseViewColor.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.leading, 13)
            .padding(.trailing, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .frame(height: 116)
        .saturation(isMuted ? 0.3 : 1.0)
        .overlay(Rectangle().strokeBorder(Color(UIColor.separator), lineWidth: 0.5))
    }
}

struct AppMembershipProgressCard: View {
    let title: String
    var badgeText: String? = nil
    var progressLabel: String
    var progressPercent: Int? = nil
    var supportingText: String
    var progress: Double?
    var footerTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BaseViewLayout.cardGap) {
            HStack {
                Text(title)
                    .font(BaseViewFont.sectionTitle)
                    .foregroundStyle(BaseViewColor.textPrimary)

                Spacer()

                if let badgeText {
                    AppBadge(text: badgeText)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(progressLabel)
                        .font(BaseViewFont.label)
                        .foregroundStyle(BaseViewColor.textSecondary)

                    Spacer()

                    if let progressPercent {
                        Text("\(progressPercent)%")
                            .font(BaseViewFont.labelStrong)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    }
                }

                if let progress {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(BaseViewColor.border.opacity(0.4))
                                .frame(height: 6)

                            Rectangle()
                                .fill(BaseViewColor.accent)
                                .frame(width: geometry.size.width * CGFloat(max(0, min(progress, 1))), height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                Text(supportingText)
                    .font(BaseViewFont.label)
                    .foregroundStyle(BaseViewColor.textSecondary)
            }

            Rectangle()
                .fill(BaseViewColor.border)
                .frame(height: BaseViewLayout.cardBorderWidth)
                .padding(.vertical, 4)

            AppButton(footerTitle, style: .underlined, fillsWidth: false, action: action)
        }
        .padding(BaseViewLayout.screenInset)
        .background(BaseViewColor.elevatedSurface)
        .overlay(
            Rectangle()
                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
    }
}

struct AppOrderSummaryCard: View {
    struct Line: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        var isTotal: Bool = false
    }

    let title: String
    let lines: [Line]
    var actionTitle: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: (() -> Void)?

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                Text(title)
                    .font(BaseViewFont.sectionTitle)
                    .foregroundStyle(BaseViewColor.textPrimary)

                ForEach(lines) { line in
                    HStack {
                        Text(line.label)
                            .font(line.isTotal ? BaseViewFont.totalLabel : BaseViewFont.body)
                            .foregroundStyle(BaseViewColor.textPrimary)

                        Spacer()

                        Text(line.value)
                            .font(line.isTotal ? BaseViewFont.monoTitle : BaseViewFont.monoBody)
                            .foregroundStyle(line.isTotal ? BaseViewColor.textPrimary : BaseViewColor.textSecondary)
                    }
                }

                if let actionTitle, let action {
                    AppButton(actionTitle, style: .primary, isLoading: isLoading, isDisabled: isDisabled, action: action)
                }
            }
        }
    }
}
