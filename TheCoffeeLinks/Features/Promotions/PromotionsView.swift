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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Header
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text("Promotions")
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
        DigitalCredentialContent(
            memberId: profileViewModel.userProfile?.shortId ?? "******",
            userName: profileViewModel.userProfile?.fullName ?? "Member",
            tier: profileViewModel.userProfile?.membershipTier.displayName ?? "Member",
            points: profileViewModel.userProfile?.points ?? 0,
            vouchersCount: profileViewModel.vouchers.count,
            ordersCount: profileViewModel.orderCount,
            onRefresh: {
                profileViewModel.loadProfile()
            }
        )
        .padding(AppLayout.spacing)
        .background(Color.surfaceCard) // Optional: If we want a card background for the inline version
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        .overlay(
             RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                 .stroke(Color.border, lineWidth: 1)
        )
    }
    
    private var guestState: some View {
        VStack(spacing: AppLayout.spacingXL) {
            Image(systemName: "ticket")
                .font(.system(size: 48))
                .foregroundStyle(Color.textMuted)
            
            Text("Sign in to access promotions")
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
            
            Text("Join our membership program to earn points, redeem vouchers, and get exclusive offers.")
                .font(AppFont.body)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
            
            Button {
                showLogin = true
            } label: {
                Text("Sign in or Join")
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.backgroundPaper)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
        }
        .padding(AppLayout.spacing)
        .background(Color.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
    }
}
