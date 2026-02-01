import SwiftUI
import CachedAsyncImage

/// Refactored ProfileView - Design System v2
/// Clean list-based layout with capsule buttons
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var showLogin = false
    @State private var showEditProfile = false
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.sectionGap) {
                    // Header
                    SectionHeader(title: "Profile")
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, AppSpacing.screenPadding)
                    
                    // Profile Card
                    if authViewModel.isAuthenticated {
                        profileHeader
                    } else {
                        guestPrompt
                    }
                    
                    // Stats
                    if authViewModel.isAuthenticated {
                        statsSection
                    }
                    
                    // Activity Section
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Activity")
                            .font(AppTypography.labelLarge)
                            .foregroundStyle(Color.textSecondary)
                            .padding(.horizontal, AppSpacing.screenPadding)
                        
                        VStack(spacing: 1) {
                            if authViewModel.isAuthenticated {
                                ListRow(title: "Order History", icon: "list.bullet", destination: OrdersView(isPresentedModally: false))
                                Divider().background(Color.borderSecondary)
                                ListRow(title: "Saved Locations", icon: "mappin.circle", destination: SavedLocationsView())
                                Divider().background(Color.borderSecondary)
                                ListRow(title: "My Vouchers", icon: "ticket") {
                                    appState.selectedTab = 3
                                }
                            } else {
                                ListRow(title: "Order History", icon: "list.bullet") { showLogin = true }
                                Divider().background(Color.borderSecondary)
                                ListRow(title: "Saved Locations", icon: "mappin.circle") { showLogin = true }
                                Divider().background(Color.borderSecondary)
                                ListRow(title: "My Vouchers", icon: "ticket") { showLogin = true }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                .stroke(Color.borderSecondary, lineWidth: 0.5)
                        )
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Settings")
                            .font(AppTypography.labelLarge)
                            .foregroundStyle(Color.textSecondary)
                            .padding(.horizontal, AppSpacing.screenPadding)
                        
                        VStack(spacing: 1) {
                            ListRow(title: "Edit Profile", icon: "person.circle") {
                                if authViewModel.isAuthenticated {
                                    showEditProfile = true
                                } else {
                                    showLogin = true
                                }
                            }
                            Divider().background(Color.borderSecondary)
                            
                            if authViewModel.isAuthenticated {
                                ListRow(title: "Security", icon: "lock.shield", destination: SecurityView())
                            } else {
                                ListRow(title: "Security", icon: "lock.shield") { showLogin = true }
                            }
                            Divider().background(Color.borderSecondary)
                            
                            ListRow(title: "Notifications", icon: "bell.badge", destination: NotificationsView())
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                .stroke(Color.borderSecondary, lineWidth: 0.5)
                        )
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Sign In / Out
                    VStack(spacing: AppSpacing.md) {
                        if authViewModel.isAuthenticated {
                            CapsuleButton("Sign Out", style: .secondary) {
                                authViewModel.logout()
                            }
                        } else {
                            CapsuleButton("Sign In or Join", style: .primary) {
                                showLogin = true
                            }
                        }
                        
                        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                            Text("Version \(appVersion)")
                                .font(AppTypography.bodySmall)
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, 100)
                }
            }
        }
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
            LoginView_v2()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        HStack(spacing: AppSpacing.lg) {
            // Avatar
            Circle()
                .fill(Color.surfaceElevated)
                .frame(width: 64, height: 64)
                .overlay {
                    if let avatarUrl = profileViewModel.userProfile?.avatarUrl {
                        CachedAsyncImage(url: URL(string: avatarUrl)) { phase in
                            if case .success(let image) = phase {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(profileViewModel.userProfile?.fullName ?? "Member")
                    .font(AppTypography.displayMedium)
                    .foregroundStyle(Color.textPrimary)
                
                Text(profileViewModel.userProfile?.membershipTier.displayName ?? "Member")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(Color.borderSecondary, lineWidth: 0.5)
        )
        .padding(.horizontal, AppSpacing.screenPadding)
    }
    
    // MARK: - Guest Prompt
    
    private var guestPrompt: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color.textTertiary)
            
            Text("Sign in for full access")
                .font(AppTypography.displayMedium)
                .foregroundStyle(Color.textPrimary)
            
            Text("Track orders, save favorites, and earn rewards")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(Color.borderSecondary, lineWidth: 0.5)
        )
        .padding(.horizontal, AppSpacing.screenPadding)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: AppSpacing.md) {
            StatCard(
                value: "\(profileViewModel.userProfile?.points ?? 0)",
                label: "Points"
            )
            
            StatCard(
                value: "\(profileViewModel.vouchers.count)",
                label: "Vouchers"
            )
            
            StatCard(
                value: "\(profileViewModel.orderCount)",
                label: "Orders"
            )
        }
        .padding(.horizontal, AppSpacing.screenPadding)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppTypography.monoLarge)
                .foregroundStyle(Color.textPrimary)
            
            Text(label)
                .font(AppTypography.bodySmall)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(Color.borderSecondary, lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(DependencyContainer.shared.makeAuthViewModel())
        .environmentObject(DependencyContainer.shared.makeProfileViewModel())
        .environmentObject(AppState())
}
