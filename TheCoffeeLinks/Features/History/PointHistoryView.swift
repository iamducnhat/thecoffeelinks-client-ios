import SwiftUI

struct PointHistoryView: View {
    @ObservedObject var session: AppSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            screenHeader

            LazyVStack(spacing: 5) {
                ForEach(Array(session.history.enumerated()), id: \.element.id) { index, transaction in
                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                        TransactionRow(transaction: transaction)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if transaction.id == session.history.last?.id {
                            Task { await session.loadMoreHistory() }
                        }
                    }

                }
                if session.nextCursor != nil {
                    ProgressView().tint(AppColor.accent).padding()
                }
            }
            .padding(.horizontal, AppSpacing.screen)
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var screenHeader: some View {
        HStack(spacing: AppSpacing.compact) {
            Button { dismiss() } label: {
                IconView(name: "chevron.left", size: 18)
                    .frame(width: AppSpacing.touchTarget, height: AppSpacing.touchTarget)
            }
            .buttonStyle(.plain)

            Text("history.title")
                .font(AppFont.screenTitle)
            Spacer()
        }
        .foregroundStyle(AppColor.textPrimary)
        .padding(.horizontal, AppSpacing.screen - 11)
        .padding(.top, 22)
        .padding(.bottom, 18)
    }
}

struct TransactionRow: View {
    let transaction: PointTransaction

    var body: some View {
        AppRow {
            VStack(alignment: .leading, spacing: AppSpacing.micro) {
                Text(transaction.storeName ?? String(localized: "history.store_unknown"))
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.textPrimary)
                Text(transaction.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                if let code = transaction.invoiceCode {
                    Text(code).font(AppFont.monoSmall).foregroundStyle(AppColor.textSecondary)
                }
            }
        } trailing: {
            Text(transaction.points > 0 ? "+\(transaction.points)" : "\(transaction.points)")
                .font(AppFont.mono)
                .foregroundStyle(transaction.isCredit ? AppColor.success : AppColor.error)
        }
    }
}

struct TransactionDetailView: View {
    let transaction: PointTransaction
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
                HStack(spacing: AppSpacing.compact) {
                    Button { dismiss() } label: {
                        IconView(name: "chevron.left", size: 18)
                            .frame(width: AppSpacing.touchTarget, height: AppSpacing.touchTarget)
                    }
                    .buttonStyle(.plain)
                    Text("history.detail").font(AppFont.screenTitle)
                    Spacer()
                }
                .padding(.leading, -11)

                Text(transaction.points > 0 ? "+\(transaction.points)" : "\(transaction.points)")
                    .font(AppFont.points)
                    .foregroundStyle(transaction.isCredit ? AppColor.success : AppColor.error)

                AppCard {
                    VStack(spacing: AppSpacing.card) {
                        detail("history.store", transaction.storeName ?? "—")
                        detail("history.time", transaction.createdAt.formatted(date: .long, time: .shortened))
                        detail("history.invoice", transaction.invoiceCode ?? "—", mono: true)
                        if let amount = transaction.eligibleAmount {
                            detail("history.eligible_amount", amount.formatted(.currency(code: "VND")))
                        }
                        if let rate = transaction.vndPerPoint {
                            detail("history.rate", String(format: String(localized: "history.rate_value"), rate.formatted(.number.grouping(.automatic))))
                        }
                    }
                }
            }
            .padding(AppSpacing.screen)
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func detail(_ key: LocalizedStringKey, _ value: String, mono: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key).font(AppFont.label).foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value).font(mono ? AppFont.monoSmall : AppFont.body).multilineTextAlignment(.trailing)
        }
    }
}
