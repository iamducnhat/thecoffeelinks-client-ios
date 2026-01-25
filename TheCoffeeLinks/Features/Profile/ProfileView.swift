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
    @State private var showSettings = false
    @State private var showOrderHistory = false
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
                            Text(String(localized: "rewards_section_title"))
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
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
                            Text(String(localized: "activity_section_title"))
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            VStack(spacing: 0) {
                                if authViewModel.isAuthenticated {
                                    ActionRow(title: String(localized: "action_order_history"), icon: "list.bullet.rectangle") { showOrderHistory = true }
                                    ActionRow(title: String(localized: "action_saved_locations"), icon: "mappin.and.ellipse") { }
                                    ActionRow(title: String(localized: "action_my_vouchers"), icon: "ticket") { }
                                } else {
                                    ActionRow(title: "Order history", icon: "list.bullet.rectangle") { showLogin = true }
                                    ActionRow(title: "Saved locations", icon: "mappin.and.ellipse") { showLogin = true }
                                    ActionRow(title: "My vouchers", icon: "ticket") { showLogin = true }
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
                            Text(String(localized: "settings_section_title"))
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            VStack(spacing: 0) {
                                ActionRow(title: String(localized: "action_edit_profile"), icon: "person") { if authViewModel.isAuthenticated { showEditProfile = true } else { showLogin = true } }
                                ActionRow(title: String(localized: "action_security"), icon: "lock.shield") { if authViewModel.isAuthenticated { showSettings = true } else { showLogin = true } }
                                ActionRow(title: String(localized: "action_notifications"), icon: "bell") { }
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
                            
                            Text("Version 1.0.4")
                                .font(AppFont.uiMicro)
                                .foregroundStyle(Color.textMuted)
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
        .fullScreenCover(isPresented: $showOrderHistory) {
            OrdersView()
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
                    // CHANGED: Using CachedAsyncImage
                    CachedAsyncImage(url: url) { phase in // CHANGED
                        switch phase { // CHANGED
                        case .empty: // CHANGED
                            Rectangle() // CHANGED
                                .fill(Color.surfaceCard) // CHANGED
                                .overlay { // CHANGED
                                    ProgressView() // CHANGED
                                        .tint(Color.primaryEspresso) // CHANGED
                                } // CHANGED
                        case .success(let image): // CHANGED
                            image // CHANGED
                                .resizable() // CHANGED
                                .aspectRatio(contentMode: .fill) // CHANGED
                        case .failure: // CHANGED
                            Rectangle() // CHANGED
                                .fill(Color.surfaceCard) // CHANGED
                                .overlay { // CHANGED
                                    Text(String(profileViewModel.userProfile?.displayName.prefix(1) ?? "U")) // CHANGED
                                        .font(.system(size: 32, weight: .bold)) // CHANGED
                                        .foregroundStyle(Color.textInk) // CHANGED
                                } // CHANGED
                        @unknown default: // CHANGED
                            EmptyView() // CHANGED
                        } // CHANGED
                    } // CHANGED
                } else {
                    Text(String(profileViewModel.userProfile?.displayName.prefix(1) ?? "U"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.textInk)
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

// MARK: - Components

struct MetricBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(AppFont.monoTitle)
                .foregroundStyle(Color.textInk)
            Text(label)
                .font(AppFont.uiMicro)
                .foregroundStyle(Color.textMuted)
        }
        .padding(AppLayout.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
    }
}

struct ActionRow: View {
    let title: String
    var icon: String = "chevron.right"
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(AppFont.body)
                    .foregroundStyle(Color.textMuted)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(Color.textInk)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textMuted)
            }
            .padding(AppLayout.spacing)
            .background(Color.backgroundPaper)
        }
    }
}
