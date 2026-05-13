import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var showLogin = false
    @State private var showEditProfile = false

    private let rowSpacing: CGFloat = 5
    private let membershipCardHeight: CGFloat = 98
    
    var body: some View {
        ZStack {
            BaseViewColor.background.ignoresSafeArea()

            if authViewModel.isAuthenticated {
                if let user = profileViewModel.userProfile {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            profileName(for: user)
                                .padding(.horizontal, BaseViewLayout.screenInset)
                                .padding(.top, BaseViewLayout.screenTopInset)

                            Spacer().frame(height: 23)

                            authenticatedSections(for: user)
                        }
                        .padding(.bottom, 100)
                    }
                } else {
                    AppLoadingState(nil as String?)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                guestPrompt
                    .padding(.horizontal, BaseViewLayout.screenInset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if authViewModel.isAuthenticated {
                profileViewModel.loadProfile()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                showLogin = false
                profileViewModel.loadProfile()
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
    }

    private func profileName(for user: User) -> some View {
        Text(user.fullName)
            .font(BaseViewFont.screenTitle)
            .foregroundStyle(BaseViewColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func authenticatedSections(for user: User) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: rowSpacing) {
                membershipCard(status: user.membershipStatus)

                Button {
                    appState.selectedTab = 3
                } label: {
                    profileRow(title: "View benefit")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, BaseViewLayout.screenInset)

            Spacer().frame(height: BaseViewLayout.majorSectionGap)

            VStack(spacing: rowSpacing) {
                NavigationLink {
                    OrdersView(isPresentedModally: false)
                } label: {
                    profileRow(title: "Order history", detail: "\(profileViewModel.orderCount)")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SavedLocationsView()
                } label: {
                    profileRow(title: "Saved locations", detail: "2")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, BaseViewLayout.screenInset)

            Spacer().frame(height: BaseViewLayout.majorSectionGap)

            VStack(spacing: rowSpacing) {
                Button {
                    showEditProfile = true
                } label: {
                    profileRow(title: "Edit profile")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SecurityView()
                } label: {
                    profileRow(title: "Security")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    NotificationsView()
                } label: {
                    profileRow(title: "Notifications")
                }
                .buttonStyle(.plain)

                Button {
                } label: {
                    profileRow(title: "Themes", detail: "Default", detailColor: BaseViewColor.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, BaseViewLayout.screenInset)

            Spacer().frame(height: BaseViewLayout.majorSectionGap)

            Button {
                authViewModel.logout()
            } label: {
                profileRow(title: "Sign out")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, BaseViewLayout.screenInset)
        }
    }

    private var guestPrompt: some View {
        AppAuthPromptCard(
            title: "Đăng nhập để sử dụng tính năng này",
            message: "Tham gia hội viên để nhận được điểm, phần thưởng\nvà nhiều ưu đãi khác.",
            actionTitle: "ĐĂNG NHẬP HOẶC THAM GIA"
        ) {
            showLogin = true
        }
    }

    private func membershipCard(status: MembershipStatus) -> some View {
        let nextTier = status.nextTier
        let progress = CGFloat(nextTier?.progressPercent ?? 100) / 100

        return VStack(alignment: .leading, spacing: 0) {
            Text("\(status.currentTier.displayName.uppercased()) MEMBER")
                .font(BaseViewFont.labelStrong)
                .tracking(2)
                .foregroundStyle(BaseViewColor.accentForeground)
                .padding(4)
                .background(status.currentTier.badgeColor)
                .padding(.top, BaseViewLayout.badgeInset)
                .padding(.horizontal, BaseViewLayout.badgeInset)

            Spacer().frame(height: 12)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(status.currentTier.badgeColor.opacity(0.2))

                    Rectangle()
                        .fill(status.currentTier.badgeColor)
                        .frame(width: geometry.size.width * max(0, min(progress, 1)))
                }
            }
            .frame(height: 3)
            .padding(.horizontal, BaseViewLayout.badgeInset)

            Spacer().frame(height: 13)

            Text(progressLabel(for: status))
                .font(BaseViewFont.labelStrong)
                .tracking(2)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(.horizontal, BaseViewLayout.badgeInset)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: membershipCardHeight)
        .background(BaseViewColor.elevatedSurface)
        .overlay(Rectangle().stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth))
    }

    private func progressLabel(for status: MembershipStatus) -> String {
        guard let nextTier = status.nextTier else {
            return "TOP TIER UNLOCKED"
        }

        return "$\(nextTier.pointsRemaining) TO \(nextTier.tier.displayName.uppercased())"
    }

    private func profileRow(
        title: String,
        detail: String? = nil,
        detailColor: Color = BaseViewColor.textSecondary
    ) -> some View {
        BaseListRow(title: title, detail: detail, detailColor: detailColor)
    }
}

private extension MembershipTier {
    var badgeColor: Color {
        switch self {
        case .bronze:
            return Color(hex: "#B82000")
        case .silver:
            return Color(hex: "#8C919A")
        case .gold:
            return Color(hex: "#B8860B")
        case .platinum:
            return Color(hex: "#4A5A6A")
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(DependencyContainer.shared.makeAuthViewModel())
        .environmentObject(DependencyContainer.shared.makeProfileViewModel())
        .environmentObject(AppState())
}
