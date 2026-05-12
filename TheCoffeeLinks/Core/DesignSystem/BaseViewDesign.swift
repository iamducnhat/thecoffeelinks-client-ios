import SwiftUI

struct BaseViewLayout {
    static let screenInset: CGFloat = 23
    static let screenTopInset: CGFloat = 23
    static let sectionGap: CGFloat = 24
    static let majorSectionGap: CGFloat = 40
    static let cardGap: CGFloat = 10
    static let cardBorderWidth: CGFloat = 0.5
    static let contentInset: CGFloat = 20
    static let badgeInset: CGFloat = 13
    static let cardTitleTwoLineHeight: CGFloat = 46
    static let displayTitleTwoLineHeight: CGFloat = 56
    static let rowHeight: CGFloat = 44
    static let smallCTAHeight: CGFloat = 40
    static let inlineCTAHeight: CGFloat = 52
    static let accentBadgeHeight: CGFloat = 26
    static let accentBadgeInset: CGFloat = 5
}

struct BaseViewColor {
    static let background = Color.bgPrimary
    static let surface = Color.surfacePrimary
    static let elevatedSurface = Color.surfaceElevated
    static let textPrimary = Color.textPrimary
    static let textSecondary = Color.textSecondary
    static let border = Color.borderPrimary
    static let accent = Color.accentPrimary
    static let accentForeground = Color.bgPrimary
    static let placeholder = Color(hex: "#D9D9D9")
    static let indicatorActive = Color(hex: "#6F6F6F")
    static let indicatorInactive = Color(hex: "#BFBFBF")
}

struct BaseViewFont {
    static let screenTitle = Font.custom("BeVietnamPro-Bold", size: 22)
    static let screenSubtitle = Font.custom("BeVietnamPro-Regular", size: 22)
    static let sectionTitle = Font.custom("BeVietnamPro-SemiBold", size: 22)
    static let cardTitle = Font.custom("BeVietnamPro-SemiBold", size: 18)
    static let body = Font.custom("BeVietnamPro-Regular", size: 18)
    static let bodyStrong = Font.custom("BeVietnamPro-SemiBold", size: 18)
    static let label = Font.custom("BeVietnamPro-Regular", size: 14)
    static let labelStrong = Font.custom("BeVietnamPro-Medium", size: 14)
    static let cta = Font.custom("BeVietnamPro-Medium", size: 14)
}

enum BaseCTAStyle {
    case filled
    case outlined
}

struct BaseCTAButton: View {
    let title: String
    var style: BaseCTAStyle = .filled
    var fillsWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BaseViewFont.cta)
                .tracking(1.6)
                .frame(maxWidth: fillsWidth ? .infinity : nil)
                .frame(minHeight: BaseViewLayout.smallCTAHeight)
                .padding(.horizontal, fillsWidth ? 0 : 18)
                .foregroundStyle(foregroundColor)
                .background(
                    Rectangle()
                        .fill(backgroundColor)
                )
                .overlay {
                    if style == .outlined {
                        Rectangle()
                            .stroke(BaseViewColor.accent, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return BaseViewColor.accent
        case .outlined:
            return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .filled:
            return BaseViewColor.accentForeground
        case .outlined:
            return BaseViewColor.accent
        }
    }
}

struct BaseUnderlinedCTA: View {
    let title: String
    var color: Color = BaseViewColor.textPrimary

    var body: some View {
        Text(title)
            .font(BaseViewFont.cta)
            .tracking(2)
            .underline()
            .foregroundStyle(color)
    }
}

struct BaseAccentBadge: View {
    let title: String

    var body: some View {
        Text(title)
            .font(BaseViewFont.labelStrong)
            .tracking(2)
            .foregroundStyle(BaseViewColor.accentForeground)
            .padding(.horizontal, BaseViewLayout.accentBadgeInset)
            .padding(.vertical, BaseViewLayout.accentBadgeInset)
            .background(BaseViewColor.accent)
    }
}

struct TwoLineText: View {
    let text: String
    let font: Font
    let color: Color
    let height: CGFloat
    var alignment: Alignment = .topLeading

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: alignment)
    }
}

struct BaseDiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct AppCheckbox: View {
    let isSelected: Bool
    var size: CGFloat = 18
    private let borderWidth: CGFloat = 2

    var body: some View {
        Rectangle()
            .fill(isSelected ? BaseViewColor.accent : BaseViewColor.elevatedSurface)
            .frame(width: size, height: size)
            .overlay(
                Rectangle()
                    .stroke(isSelected ? BaseViewColor.accent : BaseViewColor.border, lineWidth: borderWidth)
            )
    }
}

struct AppTickbox: View {
    let isSelected: Bool
    var size: CGFloat = 18
    private let borderWidth: CGFloat = 2

    var body: some View {
        BaseDiamondShape()
            .fill(isSelected ? BaseViewColor.accent : BaseViewColor.elevatedSurface)
            .frame(width: size, height: size)
            .overlay(
                BaseDiamondShape()
                    .stroke(isSelected ? BaseViewColor.accent : BaseViewColor.border, lineWidth: borderWidth)
            )
    }
}

struct BaseListRow: View {
    let title: String
    var detail: String? = nil
    var detailColor: Color = BaseViewColor.textSecondary

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(BaseViewFont.body)
                .foregroundStyle(BaseViewColor.textPrimary)

            Spacer(minLength: 12)

            if let detail {
                Text(detail)
                    .font(BaseViewFont.body)
                    .foregroundStyle(detailColor)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity)
        .background(BaseViewColor.elevatedSurface)
        .overlay(
            Rectangle()
                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
    }
}