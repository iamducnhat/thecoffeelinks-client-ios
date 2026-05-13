import SwiftUI

struct AppCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppLayout.spacing
    var backgroundColor: Color = BaseViewColor.elevatedSurface
    var borderColor: Color = BaseViewColor.border
    var borderWidth: CGFloat = AppLayout.borderWidth
    var cornerRadius: CGFloat = AppLayout.cornerRadius

    init(
        padding: CGFloat = AppLayout.spacing,
        backgroundColor: Color = BaseViewColor.elevatedSurface,
        borderColor: Color = BaseViewColor.border,
        borderWidth: CGFloat = AppLayout.borderWidth,
        cornerRadius: CGFloat = AppLayout.cornerRadius,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: AppLayout.cornerStyle))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: AppLayout.cornerStyle)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
    }
}

struct AppBadge: View {
    enum Style {
        case accent
        case neutral
        case success
        case warning
        case destructive
    }

    let text: String
    var style: Style = .accent

    var body: some View {
        Text(text)
            .font(BaseViewFont.labelStrong)
            .tracking(1.6)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, BaseViewLayout.accentBadgeInset)
            .padding(.vertical, BaseViewLayout.accentBadgeInset)
            .background(backgroundColor)
    }

    private var backgroundColor: Color {
        switch style {
        case .accent:
            return BaseViewColor.accent
        case .neutral:
            return BaseViewColor.elevatedSurface
        case .success:
            return Color.semanticSuccess
        case .warning:
            return Color.semanticWarning
        case .destructive:
            return Color.semanticError
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .neutral:
            return BaseViewColor.textPrimary
        default:
            return BaseViewColor.accentForeground
        }
    }
}

struct AppRow<Leading: View, Trailing: View>: View {
    let leading: Leading
    let trailing: Trailing
    var padding: CGFloat = BaseViewLayout.badgeInset
    var backgroundColor: Color = BaseViewColor.elevatedSurface
    var borderColor: Color = BaseViewColor.border

    init(
        padding: CGFloat = BaseViewLayout.badgeInset,
        backgroundColor: Color = BaseViewColor.elevatedSurface,
        borderColor: Color = BaseViewColor.border,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.leading = leading()
        self.trailing = trailing()
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
    }

    var body: some View {
        HStack(spacing: AppLayout.spacing) {
            leading
            Spacer(minLength: 12)
            trailing
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(borderColor, lineWidth: BaseViewLayout.cardBorderWidth)
        )
    }
}

struct AppListRow: View {
    let title: String
    var subtitle: String? = nil
    var detail: String? = nil
    var icon: String? = nil
    var detailColor: Color = BaseViewColor.textSecondary
    var badgeText: String? = nil
    var showsChevron: Bool = false
    var isSelected: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    private var content: some View {
        AppRow {
            HStack(spacing: 12) {
                if let icon {
                    IconView(name: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(BaseViewColor.textSecondary)
                        .frame(width: 24)
                }

                VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 4) {
                    Text(title)
                        .font(BaseViewFont.body)
                        .foregroundStyle(BaseViewColor.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(BaseViewFont.label)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    }
                }
            }
        } trailing: {
            HStack(spacing: 8) {
                if let badgeText {
                    AppBadge(text: badgeText, style: .neutral)
                }

                if let detail {
                    Text(detail)
                        .font(BaseViewFont.body)
                        .foregroundStyle(detailColor)
                }

                if showsChevron || action != nil {
                    IconView(name: "chevron_right")
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? BaseViewColor.accent : BaseViewColor.textSecondary)
                }
            }
        }
        .overlay(
            Rectangle()
                .stroke(isSelected ? BaseViewColor.accent : BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
    }
}

struct AppSectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    let trailing: Trailing

    init(title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: AppLayout.spacing) {
            VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 4) {
                Text(title)
                    .font(BaseViewFont.sectionTitle)
                    .foregroundStyle(BaseViewColor.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(BaseViewFont.label)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
            }

            Spacer()

            trailing
        }
    }
}

extension AppSectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) {
            EmptyView()
        }
    }
}

struct AppNavigationHeader<Trailing: View>: View {
    let title: String
    let onBack: () -> Void
    let trailing: Trailing

    init(title: String, onBack: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            Text(title)
                .font(BaseViewFont.screenTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            HStack {
                AppButton(icon: "chevron.left") {
                    onBack()
                }

                Spacer()

                trailing
            }
        }
        .frame(height: BaseViewLayout.navButtonSize)
        .padding(.horizontal, BaseViewLayout.screenInset)
        .padding(.top, BaseViewLayout.screenTopInset)
        .padding(.bottom, BaseViewLayout.screenTopInset)
    }
}

extension AppNavigationHeader where Trailing == EmptyView {
    init(title: String, onBack: @escaping () -> Void) {
        self.init(title: title, onBack: onBack) {
            EmptyView()
        }
    }
}

struct AppEmptyState: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var actionTitle: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    init(
        icon: String = "square",
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    init(
        icon: String = "square",
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(
            icon: icon,
            title: LocalizedStringKey(title),
            message: LocalizedStringKey(message),
            actionTitle: actionTitle.map { LocalizedStringKey($0) },
            action: action
        )
    }

    var body: some View {
        VStack(spacing: AppLayout.spacing) {
            IconView(name: icon)
                .font(.system(size: 40))
                .foregroundStyle(BaseViewColor.textSecondary)

            Text(title)
                .font(BaseViewFont.sectionTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(BaseViewFont.body)
                .foregroundStyle(BaseViewColor.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                AppButton(actionTitle, style: .secondary, fillsWidth: false, action: action)
            }
        }
        .padding(AppLayout.spacingXL)
        .frame(maxWidth: .infinity)
    }
}

struct AppAuthPromptCard: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(BaseViewFont.cardTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, BaseViewLayout.screenTopInset)
                .padding(.horizontal, BaseViewLayout.screenInset)

            Text(message)
                .font(BaseViewFont.label)
                .foregroundStyle(BaseViewColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, AppAuthPromptCardMetric.messageTopSpacing)
                .padding(.horizontal, BaseViewLayout.contentInset)

            Button(action: action) {
                Text(actionTitle)
                    .font(BaseViewFont.cta)
                    .tracking(2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppAuthPromptCardMetric.buttonHeight)
                    .background(Color.black)
            }
            .buttonStyle(.plain)
            .padding(.top, AppAuthPromptCardMetric.buttonTopSpacing)
            .padding(.horizontal, BaseViewLayout.screenInset)
            .padding(.bottom, AppAuthPromptCardMetric.bottomInset)
        }
        .frame(maxWidth: .infinity)
        .background(BaseViewColor.background)
    }
}

private enum AppAuthPromptCardMetric {
    static let messageTopSpacing: CGFloat = 14
    static let buttonTopSpacing: CGFloat = 27
    static let buttonHeight: CGFloat = 38
    static let bottomInset: CGFloat = 23
}

struct AppLoadingState: View {
    let message: LocalizedStringKey?

    init(_ message: LocalizedStringKey? = nil) {
        self.message = message
    }

    init(_ message: String?) {
        self.message = message.map { LocalizedStringKey($0) }
    }

    var body: some View {
        VStack(spacing: AppLayout.spacing) {
            ProgressView()
                .tint(BaseViewColor.accent)

            if let message {
                Text(message)
                    .font(BaseViewFont.label)
                    .foregroundStyle(BaseViewColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppLayout.spacingXL)
    }
}

struct AppCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.backgroundPaper.ignoresSafeArea()
            
            AppCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Card Title").fontTitle()
                    Text("This is a generic card component respecting the design system.").fontBody()
                }
            }
            .padding()
        }
    }
}
