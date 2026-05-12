import SwiftUI

struct MembershipStatusCard: View {
    let status: MembershipStatus
    var onDetailsTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BaseViewLayout.cardGap) {
            HStack {
                Text("Your \(status.currentTier.displayName) benefits")
                    .font(BaseViewFont.sectionTitle)
                    .foregroundStyle(BaseViewColor.textPrimary)

                Spacer()

                if status.discountPercent > 0 {
                    BaseAccentBadge(title: "\(Int(status.discountPercent))% OFF")
                }
            }

            if let next = status.nextTier {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("$\(next.pointsRemaining) to \(next.tier.displayName)")
                            .font(BaseViewFont.label)
                            .foregroundStyle(BaseViewColor.textSecondary)

                        Spacer()

                        Text("\(next.progressPercent)%")
                            .font(BaseViewFont.labelStrong)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(BaseViewColor.border.opacity(0.4))
                                .frame(height: 6)

                            Rectangle()
                                .fill(BaseViewColor.accent)
                                .frame(width: geometry.size.width * CGFloat(next.progressPercent) / 100, height: 6)
                        }
                    }
                    .frame(height: 6)

                    Text("Keep ordering to level up your perks.")
                        .font(BaseViewFont.label)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top tier unlocked")
                        .font(BaseViewFont.labelStrong)
                        .foregroundStyle(BaseViewColor.accent)

                    Text("You have priority perks and early-access offers.")
                        .font(BaseViewFont.label)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
            }

            Rectangle()
                .fill(BaseViewColor.border)
                .frame(height: BaseViewLayout.cardBorderWidth)
                .padding(.vertical, 4)

            Button(action: onDetailsTap) {
                HStack {
                    Text("View tier details")
                        .font(BaseViewFont.body)
                        .foregroundStyle(BaseViewColor.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(BaseViewLayout.screenInset)
        .background(BaseViewColor.elevatedSurface)
        .overlay(
            Rectangle()
                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        MembershipStatusCard(status: MembershipStatus(
            currentTier: .bronze,
            discountPercent: 5,
            pointsBalance: 50,
            nextTier: .init(tier: .silver, pointsThreshold: 201, pointsRemaining: 151, progressPercent: 25)
        )) {}

        MembershipStatusCard(status: MembershipStatus(
            currentTier: .platinum,
            discountPercent: 15,
            pointsBalance: 1200,
            nextTier: nil
        )) {}
    }
    .padding()
    .background(BaseViewColor.background)
}
