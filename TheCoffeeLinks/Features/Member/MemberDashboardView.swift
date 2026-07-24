import SwiftUI

struct MemberDashboardView: View {
    @ObservedObject var session: AppSession
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    header

                    if session.isOffline {
                        OfflineBanner()
                            .padding(.bottom, AppSpacing.compact)
                    }

                    pointsCard

                    memberCodeCard
                        .padding(.top, 5)

                    recentHistory
                        .padding(.top, AppSpacing.section)
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, 22)
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text("member.title")
                    .font(AppFont.screenTitle)
                    .foregroundStyle(AppColor.textPrimary)

                if let name = session.member?.fullName, !name.isEmpty {
                    Text(name)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textPrimary)
                }
            }

            Spacer()

            NavigationLink(destination: AccountView(session: session)) {
                Text("account.title")
                    .font(AppFont.labelStrong)
                    .tracking(2)
                    .textCase(.uppercase)
                    .underline()
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(minHeight: AppSpacing.badgeHeight)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("account.title"))
        }
        .padding(.bottom, 23)
    }

    private var pointsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 6) {
                AppBadge(text: String(localized: "member.current_points"))

                HStack(alignment: .lastTextBaseline, spacing: AppSpacing.compact) {
                    Text((session.member?.points ?? 0).formatted(.number.grouping(.automatic)))
                        .font(AppFont.points)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("member.points_unit")
                        .font(AppFont.labelStrong)
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }

    private var memberCodeCard: some View {
        AppCard {
            VStack(spacing: AppSpacing.row) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.micro) {
                        Text("member.scan_hint")
                            .font(AppFont.bodyStrong)
                        Text("member.qr_rotates")
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer(minLength: AppSpacing.compact)
                    if let qr = session.memberQR {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            AppBadge(
                                text: "\(qr.secondsRemaining(at: context.date))s",
                                style: qr.secondsRemaining(at: context.date) > 20 ? .neutral : .warning
                            )
                        }
                    }
                }

                if let qr = session.memberQR, !qr.isExpired() {
                    QRCodeView(payload: qr.payload)
                        .frame(width: 206, height: 206)
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
                    .frame(height: 206)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("member.code")
                        .font(AppFont.labelStrong)
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    Text(session.member?.memberCode ?? "—")
                        .font(AppFont.mono)
                        .tracking(2)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("member.code")
                }
            }
        }
    }

    private var recentHistory: some View {
        VStack(alignment: .leading, spacing: AppSpacing.card) {
            HStack {
                Text("history.recent")
                    .font(AppFont.sectionTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Spacer()
                NavigationLink("common.view_all", destination: PointHistoryView(session: session))
                    .font(AppFont.labelStrong)
                    .tracking(2)
                    .textCase(.uppercase)
                    .underline()
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityIdentifier("history.view_all")
            }

            if session.history.isEmpty {
                AppCard { AppStateView(kind: .empty, title: "history.empty", message: "history.empty_message") }
            } else {
                VStack(spacing: 5) {
                    ForEach(Array(session.history.prefix(5))) { transaction in
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
