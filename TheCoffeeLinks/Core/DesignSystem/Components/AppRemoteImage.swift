import SwiftUI
import CachedAsyncImage

struct AppRemoteImage<Overlay: View>: View {
    enum Source {
        case cached
        case native
    }

    let url: URL?
    let source: Source
    let contentMode: ContentMode
    let width: CGFloat?
    let height: CGFloat?
    let aspectRatio: CGFloat?
    let cornerRadius: CGFloat
    let backgroundColor: Color
    let borderColor: Color?
    let borderWidth: CGFloat
    let showsProgress: Bool
    let placeholderIcon: String?
    let placeholderText: String?
    let overlayContent: Overlay

    init(
        url: URL?,
        source: Source = .cached,
        contentMode: ContentMode = .fill,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        aspectRatio: CGFloat? = nil,
        cornerRadius: CGFloat = BaseViewLayout.cornerRadius,
        backgroundColor: Color = BaseViewColor.placeholder,
        borderColor: Color? = nil,
        borderWidth: CGFloat = BaseViewLayout.borderWidth,
        showsProgress: Bool = false,
        placeholderIcon: String? = "photo",
        placeholderText: String? = nil,
        @ViewBuilder overlay: () -> Overlay
    ) {
        self.url = url
        self.source = source
        self.contentMode = contentMode
        self.width = width
        self.height = height
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.showsProgress = showsProgress
        self.placeholderIcon = placeholderIcon
        self.placeholderText = placeholderText
        self.overlayContent = overlay()
    }

    var body: some View {
        content
            .frame(width: width, height: height)
            .modifier(AppRemoteImageAspectRatioModifier(aspectRatio: aspectRatio))
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: BaseViewLayout.cornerStyle)
            )
            .overlay {
                if let borderColor {
                    RoundedRectangle(cornerRadius: cornerRadius, style: BaseViewLayout.cornerStyle)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            placeholder

            if let url {
                switch source {
                case .cached:
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            if showsProgress {
                                placeholder
                                    .overlay {
                                        ProgressView()
                                            .tint(BaseViewColor.accent)
                                    }
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: contentMode)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .failure:
                            placeholder
                        }
                    }
                case .native:
                    AsyncImage(url: url) { phase in
                        nativeImageView(for: phase)
                    }
                }
            }

            overlayContent
        }
        .clipped()
    }

    @ViewBuilder
    private func nativeImageView(for phase: SwiftUI.AsyncImagePhase) -> some View {
        switch phase {
        case .empty:
            if showsProgress {
                placeholder
                    .overlay {
                        ProgressView()
                            .tint(BaseViewColor.accent)
                    }
            }
        case .success(let image):
            image
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failure:
            placeholder
        @unknown default:
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)

            if let placeholderText, !placeholderText.isEmpty {
                Text(placeholderText)
                    .font(BaseViewFont.body)
                    .foregroundStyle(BaseViewColor.accent)
            } else if let placeholderIcon {
                Image(placeholderIcon)
                    .font(BaseViewFont.productTitle)
                    .foregroundStyle(BaseViewColor.textPrimary.opacity(0.72))
            }
        }
    }
}

extension AppRemoteImage where Overlay == EmptyView {
    init(
        url: URL?,
        source: Source = .cached,
        contentMode: ContentMode = .fill,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        aspectRatio: CGFloat? = nil,
        cornerRadius: CGFloat = BaseViewLayout.cornerRadius,
        backgroundColor: Color = BaseViewColor.placeholder,
        borderColor: Color? = nil,
        borderWidth: CGFloat = BaseViewLayout.borderWidth,
        showsProgress: Bool = false,
        placeholderIcon: String? = "photo",
        placeholderText: String? = nil
    ) {
        self.init(
            url: url,
            source: source,
            contentMode: contentMode,
            width: width,
            height: height,
            aspectRatio: aspectRatio,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            borderWidth: borderWidth,
            showsProgress: showsProgress,
            placeholderIcon: placeholderIcon,
            placeholderText: placeholderText
        ) {
            EmptyView()
        }
    }
}

private struct AppRemoteImageAspectRatioModifier: ViewModifier {
    let aspectRatio: CGFloat?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let aspectRatio {
            content.aspectRatio(aspectRatio, contentMode: .fit)
        } else {
            content
        }
    }
}

struct AppRemoteImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: BaseViewLayout.spacing) {
            AppRemoteImage(
                url: nil,
                width: 120,
                height: 120
            )

            AppRemoteImage(
                url: nil,
                width: 120,
                height: 72,
                placeholderIcon: nil,
                placeholderText: "A"
            ) {
                Text("LIVE")
                    .font(BaseViewFont.uiMicro)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(BaseViewColor.background.opacity(0.92))
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .padding()
        .background(BaseViewColor.background)
        .previewLayout(.sizeThatFits)
    }
}