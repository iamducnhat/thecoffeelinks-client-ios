//
//  NetworkView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct NetworkView: View {
    @EnvironmentObject var networkViewModel: NetworkViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingCheckInSheet = false
    @State private var scrollOffset = CGFloat.zero
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Header
                    VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                        Text(String(localized: "space_title"))
                            .font(BaseViewFont.displayTitle)
                            .foregroundColor(BaseViewColor.textPrimary)
                            .padding(.top, BaseViewLayout.spacing)
                        
                        Text("Connect with friends at your favorite coffee spot")
                            .font(BaseViewFont.body)
                            .foregroundStyle(BaseViewColor.textSecondary)
                        
                        Color.secondary.frame(height: 1)
                    }
                    .padding(.horizontal, BaseViewLayout.spacing)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    if networkViewModel.activeCheckIn == nil {
                        IntentSelectorContent(showingCheckInSheet: $showingCheckInSheet)
                    } else {
                        ActiveNetworkingContent()
                    }
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
            }
        }
        .fullScreenCover(isPresented: $showingCheckInSheet) {
            NetworkCheckInSheet(isPresented: $showingCheckInSheet)
        }
    }
}

// MARK: - Intent Selector

struct IntentSelectorContent: View {
    @EnvironmentObject var networkViewModel: NetworkViewModel
    @Binding var showingCheckInSheet: Bool
    
    var body: some View {
        LazyVStack(spacing: BaseViewLayout.spacingXL) {
            // Intent Section
            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                Text(String(localized: "network_intent_prompt"))
                    .textCase(.uppercase)
                    .font(BaseViewFont.sectionHeader)
                    .foregroundStyle(BaseViewColor.textPrimary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BaseViewLayout.spacing) {
                    ForEach(NetworkViewModel.NetworkIntent.allCases, id: \.self) { intent in
                        IntentCard(intent: intent) {
                            networkViewModel.currentIntent = intent
                            showingCheckInSheet = true
                        }
                    }
                }
            }
            .padding(.horizontal, BaseViewLayout.spacing)
            .padding(.top, BaseViewLayout.spacing)
        }
        .padding(.bottom, 100)
    }
}

struct IntentCard: View {
    let intent: NetworkViewModel.NetworkIntent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: BaseViewLayout.spacingMedium) {
                Image(intent.icon)
                    .font(.system(size: 24))
                    .foregroundColor(BaseViewColor.accent)
                
                Text(intent.title)
                    .font(BaseViewFont.monoBody)
                    .foregroundColor(BaseViewColor.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(BaseViewColor.surface)
            .overlay(
                Capsule()
                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Active Networking

struct ActiveNetworkingContent: View {
    @EnvironmentObject var networkViewModel: NetworkViewModel
    
    var body: some View {
        LazyVStack(spacing: BaseViewLayout.spacingXL) {
            // Active Status Banner
            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                Text(String(localized: "home_active_checkin"))
                    .textCase(.uppercase)
                    .font(BaseViewFont.sectionHeader)
                    .foregroundStyle(BaseViewColor.textPrimary)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(networkViewModel.currentIntent.title)
                            .font(BaseViewFont.headline)
                            .foregroundStyle(BaseViewColor.textPrimary)
                        Text("Auto-ends in \(networkViewModel.remainingTimeDisplay)")
                            .font(BaseViewFont.uiMicro)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        networkViewModel.checkOut()
                    } label: {
                        Text(String(localized: "common_end"))
                            .font(BaseViewFont.monoBody)
                            .foregroundStyle(BaseViewColor.semanticError)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(
                                Capsule()
                                    .strokeBorder(BaseViewColor.semanticError, lineWidth: 1)
                            )
                    }
                }
                .padding(BaseViewLayout.spacing)
                .background(BaseViewColor.surface)
                .overlay(
                    Capsule()
                        .strokeBorder(BaseViewColor.accent, lineWidth: 1)
                )
            }
            .padding(.horizontal, BaseViewLayout.spacing)
            .padding(.top, BaseViewLayout.spacing)
            
            // Nearby People Section
            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                HStack {
                    Text(String(localized: "network_nearby_title"))
                        .textCase(.uppercase)
                        .font(BaseViewFont.sectionHeader)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    
                    Spacer()
                    
                    Text("\(networkViewModel.nearbyPeople.count)")
                        .font(BaseViewFont.monoBody)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
                
                if networkViewModel.nearbyPeople.isEmpty {
                    VStack(spacing: BaseViewLayout.spacing) {
                        Text(String(localized: "network_nearby_empty"))
                            .font(BaseViewFont.sectionHeader)
                            .foregroundStyle(BaseViewColor.textPrimary)
                        
                        Text(String(localized: "network_nearby_prompt"))
                            .font(BaseViewFont.body)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(60)
                    .overlay(
                        Capsule()
                            .strokeBorder(BaseViewColor.border, style: StrokeStyle(lineWidth: 1, dash: BaseViewLayout.dashedPattern))
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(networkViewModel.nearbyPeople) { user in
                            PersonRow(user: user) {
                                networkViewModel.sendConnectionRequest(to: user)
                            }
                            
                            if user.id != networkViewModel.nearbyPeople.last?.id {
                                Color.secondary.frame(height: 1)
                            }
                        }
                    }
                    .background(BaseViewColor.background)
                    .overlay(
                        Capsule()
                            .strokeBorder(BaseViewColor.border, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, BaseViewLayout.spacing)
        }
        .padding(.bottom, 100)
    }
}

struct PersonRow: View {
    let user: User
    let onConnect: () -> Void
    @State private var isConnecting = false
    
    var body: some View {
        HStack(spacing: BaseViewLayout.spacing) {
            // Avatar
            ZStack {
                Rectangle()
                    .fill(BaseViewColor.surface)
                    .frame(width: 44, height: 44)
                
                Text(user.fullName.prefix(1).uppercased())
                    .font(BaseViewFont.monoBody.bold())
                    .foregroundStyle(BaseViewColor.accent)
            }
            .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
        .overlay(
                Capsule()
                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(BaseViewFont.body)
                    .foregroundStyle(BaseViewColor.textPrimary)
                
                Text(user.jobTitle ?? "Coffee Enthusiast")
                    .font(BaseViewFont.uiMicro)
                    .foregroundStyle(BaseViewColor.textSecondary)
            }
            
            Spacer()
            
            Button {
                isConnecting = true
                onConnect()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isConnecting = false
                }
            } label: {
                if isConnecting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(BaseViewColor.accent)
                } else {
                    Text(String(localized: "network_connect_action"))
                        .font(BaseViewFont.monoBody)
                        .foregroundStyle(BaseViewColor.accent)
                }
            }
            .disabled(isConnecting)
        }
        .padding(BaseViewLayout.spacing)
    }
}

// MARK: - Check-In Sheet

struct NetworkCheckInSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var networkViewModel: NetworkViewModel
    @EnvironmentObject var storeViewModel: StoreViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(String(localized: "network_check_in_action"))
                        .font(BaseViewFont.displayTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    
                    Spacer()
                    
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(BaseViewFont.navIcon)
                            .foregroundStyle(BaseViewColor.textPrimary)
                    }
                }
                .padding(BaseViewLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: BaseViewLayout.spacingXL) {
                        // Intent Info
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text("Your intent")
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            HStack(spacing: BaseViewLayout.spacing) {
                                Image(networkViewModel.currentIntent.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(BaseViewColor.accent)
                                
                                Text(networkViewModel.currentIntent.title)
                                    .font(BaseViewFont.headline)
                                    .foregroundStyle(BaseViewColor.textPrimary)
                            }
                            .padding(BaseViewLayout.spacing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(BaseViewColor.surface)
                            .overlay(
                                Capsule()
                                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
                            )
                        }
                        
                        // Location
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text(String(localized: "common_location"))
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            if let store = storeViewModel.nearestStore {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.name)
                                        .font(BaseViewFont.headline)
                                        .foregroundStyle(BaseViewColor.textPrimary)
                                    Text(store.address)
                                        .font(BaseViewFont.uiCaption)
                                        .foregroundStyle(BaseViewColor.textSecondary)
                                }
                                .padding(BaseViewLayout.spacing)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BaseViewColor.surface)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(BaseViewColor.accent, lineWidth: 1)
                                )
                            } else {
                                HStack {
                                    ProgressView().tint(BaseViewColor.accent)
                                    Text(String(localized: "network_finding_location"))
                                        .font(BaseViewFont.body)
                                        .foregroundStyle(BaseViewColor.textSecondary)
                                }
                            }
                        }
                        
                        // Duration
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text(String(localized: "common_duration"))
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            Slider(value: $networkViewModel.checkInDuration, in: 1800...7200, step: 1800)
                                .tint(BaseViewColor.accent)
                            
                            Text("\(Int(networkViewModel.checkInDuration / 60)) minutes")
                                .font(BaseViewFont.monoBody)
                                .foregroundStyle(BaseViewColor.textPrimary)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // CTA
                        Button {
                            if let store = storeViewModel.nearestStore ?? storeViewModel.stores.first {
                                networkViewModel.checkIn(store: store, intent: networkViewModel.currentIntent)
                                isPresented = false
                            }
                        } label: {
                            Text(String(localized: "network_check_in_action"))
                                .font(BaseViewFont.monoCTA)
                                .foregroundStyle(BaseViewColor.background)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(BaseViewColor.accent)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(BaseViewLayout.spacing)
                }
            }
        }
        .onAppear {
            storeViewModel.loadStores()
        }
    }
}

extension NetworkViewModel {
    var remainingTimeDisplay: String {
        guard let checkIn = activeCheckIn else { return "0 mins" }
        let elapsed = Date().timeIntervalSince(checkIn.checkedInAt)
        let remaining = max(0, checkInDuration - elapsed)
        let minutes = Int(remaining / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes) mins"
    }
}
