import SwiftUI

struct AppRow<Leading: View, Trailing: View>: View {
    let leading: Leading
    let trailing: Trailing

    init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: AppSpacing.row) {
            leading
            Spacer(minLength: AppSpacing.compact)
            trailing
        }
        .padding(AppSpacing.row)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.elevated)
    }
}
