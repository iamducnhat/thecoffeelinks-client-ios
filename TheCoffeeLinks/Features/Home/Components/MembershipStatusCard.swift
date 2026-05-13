import SwiftUI

struct MembershipStatusCard: View {
    let status: MembershipStatus
    var onDetailsTap: () -> Void

    var body: some View {
        AppMembershipProgressCard(
            title: "Your \(status.currentTier.displayName) benefits",
            badgeText: status.discountPercent > 0 ? "\(Int(status.discountPercent))% OFF" : nil,
            progressLabel: progressLabel,
            progressPercent: status.nextTier?.progressPercent,
            supportingText: supportingText,
            progress: status.nextTier.map { Double($0.progressPercent) / 100 },
            footerTitle: "View tier details",
            action: onDetailsTap
        )
    }

    private var progressLabel: String {
        if let next = status.nextTier {
            return "$\(next.pointsRemaining) to \(next.tier.displayName)"
        }

        return "Top tier unlocked"
    }

    private var supportingText: String {
        status.nextTier == nil
            ? "You have priority perks and early-access offers."
            : "Keep ordering to level up your perks."
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
