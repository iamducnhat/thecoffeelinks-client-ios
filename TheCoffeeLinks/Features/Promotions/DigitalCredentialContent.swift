import SwiftUI

struct DigitalCredentialContent: View {
    let memberId: String
    let userName: String
    let tier: String
    let points: Int
    let vouchersCount: Int
    let ordersCount: Int
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: BaseViewLayout.sectionGap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(BaseViewFont.screenTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)

                    Text(tier)
                        .font(BaseViewFont.label)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }

                Spacer()

                Button(action: onRefresh) {
                    Image("rotate_cw")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
                .buttonStyle(.plain)
            }

            Rectangle()
                .fill(BaseViewColor.border)
                .frame(height: BaseViewLayout.cardBorderWidth)

            VStack(spacing: 12) {
                BarcodeRenderView(payload: "u:\(memberId)")
                    .frame(width: 220, height: 55, alignment: .center)
                    .padding(BaseViewLayout.badgeInset)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
                    )

                Text(memberId)
                    .font(BaseViewFont.screenSubtitle)
                    .tracking(2)
                    .foregroundStyle(BaseViewColor.textPrimary)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(BaseViewColor.border)
                .frame(height: BaseViewLayout.cardBorderWidth)

            HStack(spacing: 0) {
                statItem(value: "\(points)", label: "Points")
                Spacer()
                statItem(value: "\(vouchersCount)", label: "Vouchers")
                Spacer()
                statItem(value: "\(ordersCount)", label: "Orders")
            }
        }
        .padding(BaseViewLayout.screenInset)
        .background(BaseViewColor.elevatedSurface)
        .overlay(
            Rectangle()
                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(BaseViewFont.sectionTitle)
                .foregroundStyle(BaseViewColor.textPrimary)

            Text(label)
                .font(BaseViewFont.label)
                .foregroundStyle(BaseViewColor.textSecondary)
        }
    }
}
