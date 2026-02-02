//
//  PromotionsView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct PromotionsView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showLogin = false
    @State private var scrollOffset = CGFloat.zero
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Header
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text(String(localized: "promotions_title"))
                            .font(AppFont.displayTitle)
                            .foregroundColor(Color.textPrimary)
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
                    
                    VStack(spacing: AppLayout.spacingXL) {
                        if authViewModel.isAuthenticated {
                            memberCard
                        } else {
                            guestState
                        }
                    }
                    .padding(AppLayout.spacing)
                    .padding(.bottom, 100)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
                .refreshable {
                    await profileViewModel.manualRefresh()
                }
            }
        }
        .alert("Error", isPresented: $profileViewModel.showErrorAlert) {
            Button("OK", role: .cancel) {
                profileViewModel.refreshError = nil
            }
        } message: {
            if let error = profileViewModel.refreshError {
                Text(error.userFriendlyMessage)
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
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
    }
    
    private var memberCard: some View {
        VStack(spacing: 0) {
            DigitalCredentialContent(
                memberId: profileViewModel.userProfile?.shortId ?? "******",
                userName: profileViewModel.userProfile?.fullName ?? "Member",
                tier: profileViewModel.userProfile?.membershipTier.displayName ?? "Member",
                points: profileViewModel.userProfile?.points ?? 0,
                vouchersCount: profileViewModel.vouchers.count,
                ordersCount: profileViewModel.orderCount,
                onRefresh: {
                    Task {
                        await profileViewModel.manualRefresh()
                    }
                }
            )
            
            // Stale data indicator
            if profileViewModel.isOrderCountStale || profileViewModel.isProfileStale {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption2)
                    Text("Data may be outdated")
                        .font(AppFont.uiCaption)
                    if profileViewModel.isRefreshingProfile {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .foregroundColor(Color.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, AppLayout.spacing)
                .frame(maxWidth: .infinity)
                .background(Color.yellow.opacity(0.1))
            }
        }
        .padding(AppLayout.spacing)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
             Capsule()
                 .stroke(Color.border, lineWidth: 1)
        )
    }
    
    private var guestState: some View {
        VStack(spacing: AppLayout.spacingXL) {
            Image("ticket")
                .font(.system(size: 48))
                .foregroundStyle(Color.textSecondary)
            
            Text(String(localized: "promo_sign_in_title"))
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textPrimary)
            
            Text(String(localized: "promo_sign_in_desc"))
                .font(AppFont.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showLogin = true
            } label: {
                Text(String(localized: "auth_sign_in_or_join"))
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.bgPrimary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.accentPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(AppLayout.spacing)
        .background(Color.surfacePrimary)
        .overlay(
            Capsule()
                .stroke(Color.border, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}
