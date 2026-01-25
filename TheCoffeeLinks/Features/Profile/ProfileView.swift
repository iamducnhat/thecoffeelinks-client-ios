//
//  ProfileView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import CachedAsyncImage

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var appState: AppState // To switch tabs
    
    @State private var showLogin = false
    @State private var showEditProfile = false
    @State private var scrollOffset = CGFloat.zero
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Header
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text(String(localized: "profile_title"))
                            .font(AppFont.displayTitle)
                            .foregroundColor(Color.textInk)
                            .padding(.top, AppLayout.spacing)
                        
                        Color.secondary.frame(height: 1)
                            .padding(.horizontal, -AppLayout.spacing)
                    }
                    .padding(.horizontal, AppLayout.spacing)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    LazyVStack(spacing: AppLayout.spacingXL) {
                        // Profile Header
                        if authViewModel.isAuthenticated {
                            authenticatedHeader
                        } else {
                            guestHeader
                        }
                        
                        // Rewards Section
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            ProfileSectionHeader(title: String(localized: "rewards_section_title"))
                            
                            HStack(spacing: AppLayout.spacingMedium) {
                                if authViewModel.isAuthenticated {
                                    MetricBox(label: String(localized: "metric_points"), value: "\(profileViewModel.userProfile?.points ?? 0)")
                                    MetricBox(label: String(localized: "metric_vouchers"), value: "\(profileViewModel.vouchers.count)")
                                } else {
                                    MetricBox(label: String(localized: "metric_points"), value: "—")
                                    MetricBox(label: String(localized: "metric_vouchers"), value: "—")
                                }
                            }
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        
                        // Activity Section
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            ProfileSectionHeader(title: String(localized: "activity_section_title"))
                            
                            VStack(spacing: 0) {
                                if authViewModel.isAuthenticated {
                                    // Order History -> Push
                                    ProfileRow(title: String(localized: "action_order_history"), icon: "list.bullet.rectangle", destination: OrdersView(isPresentedModally: false))
                                    Divider()
                                    // Saved Locations -> Push
                                    ProfileRow(title: String(localized: "action_saved_locations"), icon: "mappin.and.ellipse", destination: SavedLocationsView())
                                    Divider()
                                    // My Vouchers -> Switch Tab (Action)
                                    ProfileRow(title: String(localized: "action_my_vouchers"), icon: "ticket") {
                                        appState.selectedTab = 3 // Switch to Promotions Tab (Index 3)
                                    }
                                } else {
                                    // Guest Actions -> Show Login
                                    ProfileRow(title: "Order history", icon: "list.bullet.rectangle") { showLogin = true }
                                    Divider()
                                    ProfileRow(title: "Saved locations", icon: "mappin.and.ellipse") { showLogin = true }
                                    Divider()
                                    ProfileRow(title: "My vouchers", icon: "ticket") { showLogin = true }
                                }
                            }
                            .background(Color.surfaceCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        
                        // Settings Section
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            ProfileSectionHeader(title: String(localized: "settings_section_title"))
                            
                            VStack(spacing: 0) {
                                // Edit Profile -> Modal (Sheet)
                                ProfileRow(title: String(localized: "action_edit_profile"), icon: "person") {
                                    if authViewModel.isAuthenticated {
                                        showEditProfile = true
                                    } else {
                                        showLogin = true
                                    }
                                }
                                Divider()
                                
                                // Security -> Push
                                if authViewModel.isAuthenticated {
                                    ProfileRow(title: String(localized: "action_security"), icon: "lock.shield", destination: SecurityView())
                                } else {
                                    ProfileRow(title: String(localized: "action_security"), icon: "lock.shield") { showLogin = true }
                                }
                                Divider()
                                
                                // Notifications -> Push
                                ProfileRow(title: String(localized: "action_notifications"), icon: "bell", destination: NotificationsView())
                            }
                            .background(Color.surfaceCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        
                        // Sign In / Sign Out
                        VStack(alignment: .center, spacing: AppLayout.spacing) {
                            if authViewModel.isAuthenticated {
                                Button {
                                    authViewModel.logout()
                                } label: {
                                    Text(String(localized: "sign_out_button"))
                                        .font(AppFont.monoCTA)
                                        .foregroundStyle(Color.backgroundPaper)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .background(Color.semanticError)
                                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                                }
                            } else {
                                Button {
                                    showLogin = true
                                } label: {
                                    Text(String(localized: "sign_in_join_button"))
                                        .font(AppFont.monoCTA)
                                        .foregroundStyle(Color.backgroundPaper)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .background(Color.accentColor)
                                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                                }
                            }
                            
                            // Footer
                            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                Text("Version \(appVersion)")
                                    .font(AppFont.uiMicro)
                                    .foregroundStyle(Color.textMuted)
                            } else {
                                Text("Version 1.0.0")
                                    .font(AppFont.uiMicro)
                                    .foregroundStyle(Color.textMuted)
                            }
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        .padding(.bottom, 100)
                    }
                    .padding(.top, AppLayout.spacing)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
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
            LoginView()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
    }
    
    // MARK: - Subviews
    
    private var authenticatedHeader: some View {
        HStack(spacing: AppLayout.spacing) {
            // Square Avatar
            ZStack {
                Rectangle()
                    .fill(Color.surfaceCard)
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(Color.textInk, lineWidth: 1)
                    )
                
                if let avatarUrl = profileViewModel.userProfile?.avatarUrl, let url = URL(string: avatarUrl) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.surfaceCard)
                                .overlay {
                                    ProgressView()
                                        .tint(Color.primaryEspresso)
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            fallbackAvatar
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    fallbackAvatar
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profileViewModel.userProfile?.fullName ?? String(localized: "guest_name"))
                    .font(AppFont.sectionHeader)
                    .foregroundStyle(Color.textInk)
                
                Text(profileViewModel.userProfile?.email ?? String(localized: "signed_in_placeholder"))
                    .font(AppFont.uiCaption)
                    .foregroundStyle(Color.textMuted)
                
                if let tier = profileViewModel.userProfile?.membershipTier {
                    Text(tier.displayName.uppercased())
                        .font(AppFont.monoBody)
                        .foregroundStyle(Color.primaryEspresso)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primaryEspresso.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.primaryEspresso, lineWidth: 1)
                        )
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, AppLayout.spacing)
    }
    
    private var fallbackAvatar: some View {
        Rectangle()
            .fill(Color.surfaceCard)
            .overlay {
                Text(String(profileViewModel.userProfile?.displayName.prefix(1) ?? "U"))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.textInk)
            }
    }
    
    private var guestHeader: some View {
        HStack(spacing: AppLayout.spacing) {
            ZStack {
                Rectangle()
                    .fill(Color.surfaceCard)
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(Color.textInk, lineWidth: 1)
                    )
                
                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.textMuted)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "guest_name"))
                    .font(AppFont.sectionHeader)
                    .foregroundStyle(Color.textInk)
                
                Text(String(localized: "guest_subtitle"))
                    .font(AppFont.uiCaption)
                    .foregroundStyle(Color.textMuted)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppLayout.spacing)
    }
}
