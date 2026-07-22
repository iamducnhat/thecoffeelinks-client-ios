import SwiftUI

struct MemberDashboardView: View {
    @ObservedObject var session: AppSession
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.section) {
                    if session.isOffline { OfflineBanner() }
                    pointsCard
                    memberCodeCard
                    recentHistory
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.vertical, AppSpacing.card)
            }
            .background(AppColor.background)
            .navigationTitle("member.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: AccountView(session: session)) {
                        IconView(name: "person.crop.circle", size: 22)
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(Text("account.title"))
                }
            }
            .refreshable { await session.refresh() }
        }
        .task {
            await session.refreshQR(force: true)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                await session.refreshQR()
                await session.refresh()
            }
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            Task {
                await session.refresh()
                await session.refreshQR()
            }
        }
    }

    private var pointsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.compact) {
                Text("member.current_points")
                    .font(AppFont.labelStrong)
                    .foregroundStyle(AppColor.textSecondary)
                Text((session.member?.points ?? 0).formatted(.number.grouping(.automatic)))
                    .font(AppFont.points)
                    .foregroundStyle(AppColor.textPrimary)
                Text("member.points_unit")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private var memberCodeCard: some View {
        AppCard {
            VStack(spacing: AppSpacing.card) {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.micro) {
                        Text("member.scan_hint")
                            .font(AppFont.cardTitle)
                        Text("member.qr_rotates")
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                    if let qr = session.memberQR {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            AppBadge(text: "\(qr.secondsRemaining(at: context.date))s", style: qr.secondsRemaining(at: context.date) > 20 ? .neutral : .warning)
                        }
                    }
                }

                if let qr = session.memberQR, !qr.isExpired() {
                    QRCodeView(payload: qr.payload)
                        .frame(maxWidth: 218)
                        .padding(12)
                        .background(Color.white)
                } else {
                    VStack(spacing: AppSpacing.compact) {
                        IconView(name: "wifi.slash", size: 24)
                        Text("member.manual_only")
                            .font(AppFont.label)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(.vertical, AppSpacing.card)
                }

                VStack(spacing: AppSpacing.micro) {
                    Text("member.code")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                    Text(session.member?.memberCode ?? "—")
                        .font(AppFont.mono)
                        .tracking(2)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var recentHistory: some View {
        VStack(alignment: .leading, spacing: AppSpacing.card) {
            HStack {
                Text("history.recent")
                    .font(AppFont.sectionTitle)
                Spacer()
                NavigationLink("common.view_all", destination: PointHistoryView(session: session))
                    .font(AppFont.labelStrong)
                    .foregroundStyle(AppColor.accent)
            }
            if session.history.isEmpty {
                AppCard { AppStateView(kind: .empty, title: "history.empty", message: "history.empty_message") }
            } else {
                VStack(spacing: -AppSpacing.borderWidth) {
                    ForEach(session.history.prefix(5)) { transaction in
                        NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                            TransactionRow(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: AppSpacing.compact) {
            IconView(name: "wifi.slash")
            Text("common.offline_cache").font(AppFont.labelStrong)
        }
        .foregroundStyle(AppColor.textPrimary)
        .padding(AppSpacing.row)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.warning.opacity(0.18))
    }
}
