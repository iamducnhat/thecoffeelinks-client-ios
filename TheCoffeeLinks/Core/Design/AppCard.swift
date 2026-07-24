import SwiftUI

struct AppCard<Content: View>: View {
    var padding: CGFloat = AppSpacing.card
    let content: Content

    init(padding: CGFloat = AppSpacing.card, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.elevated)
            .overlay {
                Rectangle().strokeBorder(AppColor.border, lineWidth: AppSpacing.borderWidth)
            }
    }
}
