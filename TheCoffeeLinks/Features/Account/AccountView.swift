import SwiftUI

struct AccountView: View {
    @ObservedObject var session: AppSession
    @State private var showsDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                AppCard {
                    VStack(spacing: AppSpacing.card) {
                        accountRow("account.name", session.member?.fullName ?? "—")
                        accountRow("account.phone", session.member?.maskedPhone ?? "—", mono: true)
                        accountRow("account.member_since", session.member?.memberSince.formatted(date: .long, time: .omitted) ?? "—")
                    }
                }

                VStack(spacing: 10) {
                    AppButton(title: "account.sign_out", style: .secondary) { Task { await session.signOut() } }
                    AppButton(title: "account.delete", style: .destructive) { showsDelete = true }

                    Text("account.delete_shared_warning")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.top, AppSpacing.micro)
                }
            }
            .padding(AppSpacing.screen)
        }
        .background(AppColor.background)
        .navigationTitle("account.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $showsDelete) { DeleteAccountView(session: session) }
    }

    private func accountRow(_ key: LocalizedStringKey, _ value: String, mono: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key).font(AppFont.label).foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value).font(mono ? AppFont.monoSmall : AppFont.bodyStrong).multilineTextAlignment(.trailing)
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
