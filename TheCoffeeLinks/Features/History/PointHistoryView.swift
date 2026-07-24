import SwiftUI

struct PointHistoryView: View {
    @ObservedObject var session: AppSession

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
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

                    if index < session.history.count - 1 {
                        Rectangle()
                            .fill(AppColor.borderMuted)
                            .frame(height: AppSpacing.borderWidth)
                    }
                }
                if session.nextCursor != nil {
                    ProgressView().tint(AppColor.accent).padding()
                }
            }
            .background(AppColor.elevated)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                    .strokeBorder(AppColor.border, lineWidth: AppSpacing.borderWidth)
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, AppSpacing.card)
        }
        .background(AppColor.background)
        .navigationTitle("history.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
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

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
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
        .navigationTitle("history.detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func detail(_ key: LocalizedStringKey, _ value: String, mono: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key).font(AppFont.label).foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value).font(mono ? AppFont.monoSmall : AppFont.body).multilineTextAlignment(.trailing)
        }
    }
}
