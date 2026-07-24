import SwiftUI

struct MemberDashboardView: View {
    @ObservedObject var session: AppSession
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.section) {
                    header
                    if session.isOffline { OfflineBanner() }
                    pointsSummary
                    memberCodeCard
                    recentHistory
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, AppSpacing.card)
                .padding(.bottom, AppSpacing.section)
            }
            .background(AppColor.background)
            .toolbar(.hidden, for: .navigationBar)
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

    private var header: some View {
        HStack(alignment: .center) {
            Text("member.title")
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            NavigationLink(destination: AccountView(session: session)) {
                IconView(name: "person.crop.circle", size: 24)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: AppSpacing.touchTarget, height: AppSpacing.touchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("account.title"))
        }
    }

    private var pointsSummary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            Text("member.current_points")
                .font(AppFont.labelStrong)
                .tracking(1.2)
                .foregroundStyle(AppColor.textSecondary)

            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text((session.member?.points ?? 0).formatted(.number.grouping(.automatic)))
                    .font(AppFont.points)
                    .foregroundStyle(AppColor.textPrimary)

                Text("member.points_unit")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 24)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColor.border)
                .frame(height: AppSpacing.borderWidth)
        }
    }

    private var memberCodeCard: some View {
        AppCard {
            VStack(spacing: 20) {
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

                Rectangle()
                    .fill(AppColor.borderMuted)
                    .frame(height: AppSpacing.borderWidth)

                if let qr = session.memberQR, !qr.isExpired() {
                    QRCodeView(payload: qr.payload)
                        .frame(maxWidth: 206)
                        .padding(10)
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
                        .accessibilityIdentifier("member.code")
                }
                .padding(.top, AppSpacing.micro)
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
                let transactions = Array(session.history.prefix(5))
                VStack(spacing: 0) {
                    ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                        NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                            TransactionRow(transaction: transaction)
                        }
                        .buttonStyle(.plain)

                        if index < transactions.count - 1 {
                            Rectangle()
                                .fill(AppColor.borderMuted)
                                .frame(height: AppSpacing.borderWidth)
                        }
                    }
                }
                .background(AppColor.elevated)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                        .strokeBorder(AppColor.border, lineWidth: AppSpacing.borderWidth)
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
