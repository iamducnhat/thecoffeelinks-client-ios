import SwiftUI

struct BaseViewLayout {
    // MARK: - Core spacing derived from current app artwork
    static let zero: CGFloat = 0
    static let badgeInset: CGFloat = 13
    static let screenInset: CGFloat = 23
    static let screenTopInset: CGFloat = 23

    // MARK: - Spacing scale
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let unit: CGFloat = 18
    static let halfUnit: CGFloat = 9
    static let spacingMicro: CGFloat = 4
    static let spacingSmall: CGFloat = 6
    static let spacingCompact: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacing: CGFloat = 18
    static let spacingLarge: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let sectionGap: CGFloat = 24
    static let majorSectionGap: CGFloat = 40
    static let cardGap: CGFloat = 10
    static let contentInset: CGFloat = 20
    static let screenPadding: CGFloat = 16
    static let margin: CGFloat = 18
    static let marginRelaxed: CGFloat = 24
    static let marginCompact: CGFloat = 16

    // MARK: - Components
    static let cardBorderWidth: CGFloat = 0.5
    static let borderWidth: CGFloat = 1
    static let cornerRadius: CGFloat = 4
    static let cornerStyle: RoundedCornerStyle = .continuous
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusCapsule: CGFloat = 9999
    static let touchTarget: CGFloat = 44
    static let rowHeight: CGFloat = 44
    static let inputMinHeight: CGFloat = 44
    static let buttonMinHeight: CGFloat = 44
    static let accentBadgeHeight: CGFloat = 26
    static let accentBadgeInset: CGFloat = 5
    static let navButtonSize: CGFloat = 23
    static let iconSize: CGFloat = 24
    static let productImageSize: CGFloat = 80
    static let quantityMinWidth: CGFloat = 36
    static let stepperPadding: CGFloat = 4
    static let waveStepWidth: CGFloat = 18
    static let dashedPattern: [CGFloat] = [2]

    // MARK: - Text sizing helpers
    static let cardTitleTwoLineHeight: CGFloat = 46
    static let displayTitleTwoLineHeight: CGFloat = 56
}

struct BaseViewColor {
    static let background = Color.backgroundPaper
    static let surface = Color.surfaceCard
    static let elevatedSurface = Color.white
    static let tertiaryBackground = Color(white: 0.94)

    static let textPrimary = Color.textInk
    static let textSecondary = Color.textMuted
    static let textTertiary = Color(white: 0.5)
    static let textDisabled = Color(white: 0.7)

    static let border = Color.border
    static let borderSecondary = Color.borderTertiary
    static let accent = Color.primaryEspresso
    static let accentForeground = Color.backgroundPaper

    static let semanticError = Color.semanticError
    static let semanticSuccess = Color.semanticSuccess
    static let semanticWarning = Color.semanticWarning

    static let placeholder = Color(hex: "#D9D9D9")
    static let indicatorActive = Color(hex: "#6F6F6F")
    static let indicatorInactive = Color(hex: "#BFBFBF")
}

struct BaseViewFont {
    // MARK: - Vietnamese app face
    static let screenTitle = Font.custom("BeVietnamPro-Bold", size: 22)
    static let screenSubtitle = Font.custom("BeVietnamPro-Regular", size: 22)
    static let sectionTitle = Font.custom("BeVietnamPro-SemiBold", size: 22)
    static let cardTitle = Font.custom("BeVietnamPro-SemiBold", size: 18)
    static let body = Font.custom("BeVietnamPro-Regular", size: 18)
    static let bodyStrong = Font.custom("BeVietnamPro-SemiBold", size: 18)
    static let label = Font.custom("BeVietnamPro-Regular", size: 14)
    static let labelStrong = Font.custom("BeVietnamPro-Medium", size: 14)
    static let cta = Font.custom("BeVietnamPro-Medium", size: 14)

    // MARK: - Receipt/editorial face kept as canonical tokens
    static let displayTitle = Font.custom("GeologicaThinRoman-Bold", size: 28)
    static let displayMedium = Font.custom("GeologicaThinRoman-Medium", size: 22)
    static let sectionHeader = Font.custom("GeologicaThinRoman-Medium", size: 20)
    static let totalLabel = Font.custom("GeologicaThinRoman-Medium", size: 28)
    static let headline = Font.custom("GeologicaThinRoman-Medium", size: 17)
    static let navIcon = Font.custom("GeologicaThinRoman-Medium", size: 22)
    static let uiTitle = Font.custom("GeologicaThinRoman-Medium", size: 17)
    static let uiBody = Font.custom("GeologicaThinRoman-Regular", size: 17)
    static let uiCaption = Font.custom("GeologicaThinRoman-Regular", size: 16)
    static let uiMicro = Font.custom("GeologicaThinRoman-Medium", size: 12)
    static let uiButton = Font.custom("GeologicaThinRoman-SemiBold", size: 17)
    static let bodyLarge = Font.custom("GeologicaThinRoman-Regular", size: 17)
    static let bodyMedium = Font.custom("GeologicaThinRoman-Regular", size: 15)
    static let bodySmall = Font.custom("GeologicaThinRoman-Regular", size: 13)
    static let labelLarge = Font.custom("GeologicaThinRoman-Medium", size: 17)
    static let labelMedium = Font.custom("GeologicaThinRoman-Medium", size: 15)
    static let labelSmall = Font.custom("GeologicaThinRoman-Medium", size: 12)
    static let productTitle = Font.custom("GeologicaThinRoman-Bold", size: BaseViewLayout.unit)

    // MARK: - Monospace
    static let mono = Font.custom("NotoSansMono-Regular", size: 17)
    static let monoBody = Font.custom("NotoSansMono-Regular", size: 17)
    static let monoHeadline = Font.custom("NotoSansMono-Medium", size: 17)
    static let monoTitle = Font.custom("NotoSansMono-Medium", size: 28)
    static let monoCTA = Font.custom("NotoSansMono-Medium", size: 22)
    static let monoCaption = Font.custom("NotoSansMono-Regular", size: 12)
    static let monoLarge = Font.custom("NotoSansMono-Medium", size: 22)
    static let monoMedium = Font.custom("NotoSansMono-Regular", size: 17)
    static let monoSmall = Font.custom("NotoSansMono-Regular", size: 13)
}

// MARK: - View Modifiers

extension View {
    func fontDisplayTitle() -> some View { font(BaseViewFont.displayTitle) }
    func fontSectionHeader() -> some View { font(BaseViewFont.sectionHeader) }
    func fontMonoBody() -> some View { font(BaseViewFont.monoBody) }
    func fontMonoHeadline() -> some View { font(BaseViewFont.monoHeadline) }
    func fontMonoTitle() -> some View { font(BaseViewFont.monoTitle) }
    func fontBody() -> some View { font(BaseViewFont.body) }
    func fontH1() -> some View { font(BaseViewFont.displayTitle) }
    func fontH2() -> some View { font(BaseViewFont.sectionHeader) }
    func fontTitle() -> some View { font(BaseViewFont.uiTitle) }
    func fontCaption() -> some View { font(BaseViewFont.uiCaption) }
    func fontMicro() -> some View { font(BaseViewFont.uiMicro) }
    func fontButton() -> some View { font(BaseViewFont.uiButton) }
    func screenPadding() -> some View { padding(.horizontal, BaseViewLayout.margin) }
    func screenPaddingRelaxed() -> some View { padding(.horizontal, BaseViewLayout.marginRelaxed) }
    func sectionSpacing() -> some View { padding(.vertical, BaseViewLayout.spacing) }
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
        AppButton(
            title,
            style: style == .filled ? .primary : .secondary,
            fillsWidth: fillsWidth,
            action: action
        )
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
        AppBadge(text: title)
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
            .frame(maxWidth: .infinity, minHeight: height, alignment: alignment)
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
        AppListRow(
            title: title,
            detail: detail,
            detailColor: detailColor
        )
    }
}
