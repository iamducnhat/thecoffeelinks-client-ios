//
//  NetworkView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Header
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text(String(localized: "space_title"))
                            .font(AppFont.displayTitle)
                            .foregroundColor(Color.textInk)
                            .padding(.top, AppLayout.spacing)
                        
                        Text("Connect with friends at your favorite coffee spot")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                        
                        Color.secondary.frame(height: 1)
                    }
                    .padding(.horizontal, AppLayout.spacing)
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
        LazyVStack(spacing: AppLayout.spacingXL) {
            // Intent Section
            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                Text(String(localized: "network_intent_prompt"))
                    .textCase(.uppercase)
                    .font(AppFont.sectionHeader)
                    .foregroundStyle(Color.textInk)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppLayout.spacing) {
                    ForEach(NetworkViewModel.NetworkIntent.allCases, id: \.self) { intent in
                        IntentCard(intent: intent) {
                            networkViewModel.currentIntent = intent
                            showingCheckInSheet = true
                        }
                    }
                }
            }
            .padding(.horizontal, AppLayout.spacing)
            .padding(.top, AppLayout.spacing)
        }
        .padding(.bottom, 100)
    }
}

struct IntentCard: View {
    let intent: NetworkViewModel.NetworkIntent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppLayout.spacingMedium) {
                Image(intent.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color.primaryEspresso)
                
                Text(intent.title)
                    .font(AppFont.monoBody)
                    .foregroundColor(Color.textInk)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Active Networking

struct ActiveNetworkingContent: View {
    @EnvironmentObject var networkViewModel: NetworkViewModel
    
    var body: some View {
        LazyVStack(spacing: AppLayout.spacingXL) {
            // Active Status Banner
            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                Text(String(localized: "home_active_checkin"))
                    .textCase(.uppercase)
                    .font(AppFont.sectionHeader)
                    .foregroundStyle(Color.textInk)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(networkViewModel.currentIntent.title)
                            .font(AppFont.headline)
                            .foregroundStyle(Color.textInk)
                        Text("Auto-ends in \(networkViewModel.remainingTimeDisplay)")
                            .font(AppFont.uiMicro)
                            .foregroundStyle(Color.textMuted)
                    }
                    
                    Spacer()
                    
                    Button {
                        networkViewModel.checkOut()
                    } label: {
                        Text(String(localized: "common_end"))
                            .font(AppFont.monoBody)
                            .foregroundStyle(Color.semanticError)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.semanticError, lineWidth: 1)
                            )
                    }
                }
                .padding(AppLayout.spacing)
                .background(Color.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(Color.primaryEspresso, lineWidth: 1)
                )
            }
            .padding(.horizontal, AppLayout.spacing)
            .padding(.top, AppLayout.spacing)
            
            // Nearby People Section
            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                HStack {
                    Text(String(localized: "network_nearby_title"))
                        .textCase(.uppercase)
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Text("\(networkViewModel.nearbyPeople.count)")
                        .font(AppFont.monoBody)
                        .foregroundStyle(Color.textMuted)
                }
                
                if networkViewModel.nearbyPeople.isEmpty {
                    VStack(spacing: AppLayout.spacing) {
                        Text(String(localized: "network_nearby_empty"))
                            .font(AppFont.sectionHeader)
                            .foregroundStyle(Color.textInk)
                        
                        Text(String(localized: "network_nearby_prompt"))
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(60)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(Color.border, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
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
                    .background(Color.backgroundPaper)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(Color.border, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, AppLayout.spacing)
        }
        .padding(.bottom, 100)
    }
}

struct PersonRow: View {
    let user: User
    let onConnect: () -> Void
    @State private var isConnecting = false
    
    var body: some View {
        HStack(spacing: AppLayout.spacing) {
            // Avatar
            ZStack {
                Rectangle()
                    .fill(Color.surfaceCard)
                    .frame(width: 44, height: 44)
                
                Text(user.fullName.prefix(1).uppercased())
                    .font(AppFont.monoBody.bold())
                    .foregroundStyle(Color.primaryEspresso)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(Color.border, lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(AppFont.body)
                    .foregroundStyle(Color.textInk)
                
                Text(user.jobTitle ?? "Coffee Enthusiast")
                    .font(AppFont.uiMicro)
                    .foregroundStyle(Color.textMuted)
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
                        .tint(Color.primaryEspresso)
                } else {
                    Text(String(localized: "network_connect_action"))
                        .font(AppFont.monoBody)
                        .foregroundStyle(Color.primaryEspresso)
                }
            }
            .disabled(isConnecting)
        }
        .padding(AppLayout.spacing)
    }
}

// MARK: - Check-In Sheet

struct NetworkCheckInSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var networkViewModel: NetworkViewModel
    @EnvironmentObject var storeViewModel: StoreViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(String(localized: "network_check_in_action"))
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textInk)
                    }
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppLayout.spacingXL) {
                        // Intent Info
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Your intent")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            HStack(spacing: AppLayout.spacing) {
                                Image(networkViewModel.currentIntent.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.primaryEspresso)
                                
                                Text(networkViewModel.currentIntent.title)
                                    .font(AppFont.headline)
                                    .foregroundStyle(Color.textInk)
                            }
                            .padding(AppLayout.spacing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.surfaceCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                        }
                        
                        // Location
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text(String(localized: "common_location"))
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            if let store = storeViewModel.nearestStore {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.name)
                                        .font(AppFont.headline)
                                        .foregroundStyle(Color.textInk)
                                    Text(store.address)
                                        .font(AppFont.uiCaption)
                                        .foregroundStyle(Color.textMuted)
                                }
                                .padding(AppLayout.spacing)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surfaceCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.primaryEspresso, lineWidth: 1)
                                )
                            } else {
                                HStack {
                                    ProgressView().tint(Color.primaryEspresso)
                                    Text(String(localized: "network_finding_location"))
                                        .font(AppFont.body)
                                        .foregroundStyle(Color.textMuted)
                                }
                            }
                        }
                        
                        // Duration
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text(String(localized: "common_duration"))
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            Slider(value: $networkViewModel.checkInDuration, in: 1800...7200, step: 1800)
                                .tint(Color.primaryEspresso)
                            
                            Text("\(Int(networkViewModel.checkInDuration / 60)) minutes")
                                .font(AppFont.monoBody)
                                .foregroundStyle(Color.textInk)
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
                                .font(AppFont.monoCTA)
                                .foregroundStyle(Color.backgroundPaper)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        }
                    }
                    .padding(AppLayout.spacing)
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
