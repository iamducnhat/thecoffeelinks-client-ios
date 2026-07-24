import SwiftUI

struct AccountView: View {
    @ObservedObject var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @State private var showsDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                screenHeader

                VStack(spacing: 5) {
                    accountRow("account.name", session.member?.fullName ?? "—")
                    accountRow("account.phone", session.member?.maskedPhone ?? "—", mono: true)
                    accountRow("account.member_since", session.member?.memberSince.formatted(date: .long, time: .omitted) ?? "—")
                }

                VStack(spacing: 5) {
                    AppButton(title: "account.sign_out", style: .secondary) { Task { await session.signOut() } }
                    AppButton(title: "account.delete", style: .destructive) { showsDelete = true }

                    Text("account.delete_shared_warning")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.top, AppSpacing.compact)
                }
                .padding(.top, AppSpacing.section)
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, 22)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showsDelete) { DeleteAccountView(session: session) }
    }

    private var screenHeader: some View {
        HStack(spacing: AppSpacing.compact) {
            Button { dismiss() } label: {
                IconView(name: "chevron.left", size: 18)
                    .frame(width: AppSpacing.touchTarget, height: AppSpacing.touchTarget)
            }
            .buttonStyle(.plain)

            Text("account.title")
                .font(AppFont.screenTitle)
            Spacer()
        }
        .foregroundStyle(AppColor.textPrimary)
        .padding(.leading, -11)
        .padding(.bottom, 18)
    }

    private func accountRow(_ key: LocalizedStringKey, _ value: String, mono: Bool = false) -> some View {
        AppRow {
            Text(key)
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.textPrimary)
        } trailing: {
            Text(value)
                .font(mono ? AppFont.monoSmall : AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct DeleteAccountView: View {
    @ObservedObject var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @State private var otp = ""
    @State private var otpSent = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                Text("account.delete_explanation")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
                if otpSent {
                    AppOTPField(code: $otp)
                    AppButton(
                        title: "account.delete_confirm",
                        style: .destructive,
                        isLoading: session.isBusy,
                        isDisabled: otp.count != 6
                    ) {
                        Task { if await session.deleteAccount(otp: otp) { dismiss() } }
                    }
                } else {
                    AppButton(title: "account.send_delete_otp", style: .destructive, isLoading: session.isBusy) {
                        Task { if await session.sendDeletionOTP() { otpSent = true } }
                    }
                }
                Spacer()
            }
            .padding(AppSpacing.screen)
            .background(AppColor.background)
            .navigationTitle("account.delete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
                }
            }
        }
    }
}
