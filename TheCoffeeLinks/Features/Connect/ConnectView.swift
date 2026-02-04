//
//  ConnectView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import CachedAsyncImage

struct ConnectView: View {
    @StateObject private var viewModel: SocialViewModel
    @StateObject private var storesViewModel: StoresViewModel
    @State private var showingStoreSelector = false
    @State private var showingCheckIn = false
    @State private var showingModeSelector = false
    @State private var selectedUser: StorePresence?
    @State private var showingReport = false
    @State private var scrollOffset = CGFloat.zero
    
    init(viewModel: SocialViewModel, storesViewModel: StoresViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _storesViewModel = StateObject(wrappedValue: storesViewModel)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Header
                    VStack(spacing: AppSpacing.lg) {
                        SectionHeader(
                            title: String(localized: "network_connect_action"),
                            subtitle: "Find friends at your local coffee shop"
                        )
                        .padding(.horizontal, AppSpacing.screenPadding)
                        
                        Divider().background(Color.borderSecondary)
                    }
                    .padding(.top, AppSpacing.sm)
                    .background(Color.bgPrimary)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    LazyVStack(spacing: AppLayout.spacingXL) {
                        if viewModel.isCheckedIn {
                            // Active Check-In Status
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("Currently at")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textPrimary)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(storesViewModel.selectedStore?.name ?? "Unknown")
                                            .font(AppFont.headline)
                                            .foregroundStyle(Color.textPrimary)
                                        Text(viewModel.currentMode.displayName)
                                            .font(AppFont.uiCaption)
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        Task { await viewModel.checkOut() }
                                    } label: {
                                        Text("Leave")
                                            .font(AppFont.monoBody)
                                            .foregroundStyle(Color.stateError)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(Color.stateError, lineWidth: 1)
                                            )
                                    }
                                }
                                .padding(AppLayout.spacing)
                                .background(Color.surfacePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                        .strokeBorder(Color.accentPrimary, lineWidth: 1)
                                )
                                
                                Button {
                                    showingModeSelector = true
                                } label: {
                                    Text("Change status")
                                        .font(AppFont.body)
                                        .foregroundStyle(Color.accentPrimary)
                                }
                            }
                            .padding(.horizontal, AppLayout.spacing)
                            
                            // Nearby People
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("People here")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textPrimary)
                                
                                if !viewModel.nearbyUsers.isEmpty {
                                    VStack(spacing: 0) {
                                        ForEach(viewModel.nearbyUsers) { user in
                                            PresenceRow(user: user) {
                                                selectedUser = user
                                            }
                                            
                                            if user.id != viewModel.nearbyUsers.last?.id {
                                                Color.secondary.frame(height: 1)
                                            }
                                        }
                                    }
                                    .background(Color.bgPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                            .strokeBorder(Color.border, lineWidth: 1)
                                    )
                                } else {
                                    VStack(spacing: AppLayout.spacing) {
                                        Text(String(localized: "network_nearby_empty"))
                                            .font(AppFont.sectionHeader)
                                            .foregroundStyle(Color.textPrimary)
                                        
                                        Text(String(localized: "network_nearby_prompt"))
                                            .font(AppFont.body)
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(60)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                            .strokeBorder(Color.border, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                                    )
                                }
                            }
                            .padding(.horizontal, AppLayout.spacing)
                        } else {
                            // Offline Prompt
                            VStack(spacing: AppLayout.spacingXL) {
                                Text("Connect with people")
                                    .font(AppFont.displayTitle)
                                    .foregroundStyle(Color.textPrimary)
                                
                                Text("Check in to a coffee shop to see who else is there and start a conversation.")
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Button {
                                    showingStoreSelector = true
                                } label: {
                                    Text(String(localized: "network_check_in_action"))
                                        .font(AppFont.monoCTA)
                                        .foregroundStyle(Color.bgPrimary)
                                        .padding(.horizontal, 48)
                                        .padding(.vertical, 12)
                                        .background(Color.accentPrimary)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 60)
                        }
                        
                        // Privacy & Safety
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Privacy & Safety")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            VStack(spacing: 0) {
                                ProfileRow(title: "Block users", icon: "circle_x") { }
                                ProfileRow(title: "Report a concern", icon: "triangle_alert") { showingReport = true }
                            }
                            .background(Color.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                    .strokeBorder(Color.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, AppLayout.spacing)
                    }
                    .padding(.top, AppLayout.spacing)
                    .padding(.bottom, 100)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
            }
        }
        .fullScreenCover(isPresented: $showingStoreSelector) {
            StoreSelectionSheet(viewModel: storesViewModel) { store in
                showingCheckIn = true
            }
        }
        .fullScreenCover(isPresented: $showingCheckIn) {
            CheckInSheet(
                storeName: storesViewModel.selectedStore?.name,
                onCheckIn: { mode in
                    Task {
                        await viewModel.checkIn(
                            storeId: storesViewModel.selectedStore?.id ?? "",
                            mode: mode
                        )
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showingModeSelector) {
            ModeSheet(
                currentMode: viewModel.currentMode,
                onSelect: { mode in
                    Task { await viewModel.updateMode(mode) }
                }
            )
        }
        .fullScreenCover(item: $selectedUser) { user in
            UserProfileSheet(
                user: user,
                onSendRequest: { message in
                    Task {
                        await viewModel.sendConnectionRequest(to: user.userId, message: message)
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showingReport) {
            ReportSheet(onSubmit: { reason, details in })
        }
        .task {
            await viewModel.loadPresences()
        }
    }
}

// MARK: - Presence Row

struct PresenceRow: View {
    let user: StorePresence
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppLayout.spacing) {
                // Avatar
                ZStack {
                    Rectangle()
                        .fill(Color.surfacePrimary)
                        .frame(width: 44, height: 44)
                    
                    if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                        CachedAsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.surfacePrimary)
                                    .overlay {
                                        ProgressView()
                                            .tint(Color.accentPrimary)
                                    }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.surfacePrimary)
                                    .overlay {
                                        Text(user.displayName.prefix(1))
                                            .font(AppFont.body)
                                            .foregroundStyle(Color.accentPrimary)
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Text(user.displayName.prefix(1))
                            .font(AppFont.body)
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .strokeBorder(Color.border, lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(AppFont.body)
                        .foregroundStyle(Color.textPrimary)
                    Text(user.status.displayName)
                        .font(AppFont.uiMicro)
                        .foregroundStyle(Color.textSecondary)
                }
                
                Spacer()
                
                if user.mode == .open {
                    Image("message_circle")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.accentPrimary)
                }
            }
            .padding(AppLayout.spacing)
        }
    }
}

// MARK: - Check-In Sheet

struct CheckInSheet: View {
    let storeName: String?
    let onCheckIn: (ConnectionMode) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: ConnectionMode = .open
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(String(localized: "network_check_in_action"))
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppLayout.spacingXL) {
                        // Location
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text(String(localized: "common_location"))
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            Text(storeName ?? "Unknown")
                                .font(AppFont.headline)
                                .foregroundStyle(Color.textPrimary)
                                .padding(AppLayout.spacing)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surfacePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                        .strokeBorder(Color.border, lineWidth: 1)
                                )
                        }
                        
                        // Visibility Mode
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Visibility")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            ForEach(ConnectionMode.allCases, id: \.self) { mode in
                                Button {
                                    selectedMode = mode
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(mode.displayName)
                                                .font(AppFont.body)
                                                .foregroundStyle(selectedMode == mode ? .white : Color.textPrimary)
                                            Text(mode.description)
                                                .font(AppFont.uiMicro)
                                                .foregroundStyle(selectedMode == mode ? .white : Color.textSecondary)
                                        }
                                        Spacer()
                                        if selectedMode == mode {
                                            Image("checkmark")
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(AppLayout.spacing)
                                    .background(selectedMode == mode ? Color.accentPrimary : Color.bgPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous).strokeBorder(selectedMode == mode ? Color.accentPrimary : Color.borderPrimary, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                        
                        // CTA
                        Button {
                            onCheckIn(selectedMode)
                            dismiss()
                        } label: {
                            Text("Confirm Check-In")
                                .font(AppFont.monoCTA)
                                .foregroundStyle(Color.bgPrimary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.accentPrimary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}

// MARK: - Mode Sheet

struct ModeSheet: View {
    let currentMode: ConnectionMode
    let onSelect: (ConnectionMode) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Change Status")
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    LazyVStack(spacing: AppLayout.spacing) {
                        ForEach(ConnectionMode.allCases, id: \.self) { mode in
                            Button {
                                onSelect(mode)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(mode.displayName)
                                        .font(AppFont.body)
                                        .foregroundStyle(currentMode == mode ? .white : Color.textPrimary)
                                    Spacer()
                                    if currentMode == mode {
                                        Image("checkmark")
                                            .foregroundStyle(.white)
                                    }
                                }
                                .padding(AppLayout.spacing)
                                .background(currentMode == mode ? Color.accentPrimary : Color.bgPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous).strokeBorder(currentMode == mode ? Color.accentPrimary : Color.borderPrimary, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}

// MARK: - User Profile Sheet

struct UserProfileSheet: View {
    let user: StorePresence
    let onSendRequest: (String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingMessageInput = false
    @State private var message = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                .padding(AppLayout.spacing)
                
                ScrollView {
                    VStack(spacing: AppLayout.spacingXL) {
                        // Avatar & Info
                        VStack(spacing: AppLayout.spacing) {
                            ZStack {
                                Rectangle()
                                    .fill(Color.surfacePrimary)
                                    .frame(width: 100, height: 100)
                                
                                if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                                    CachedAsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            Rectangle()
                                                .fill(Color.surfacePrimary)
                                                .overlay {
                                                    ProgressView()
                                                        .tint(Color.accentPrimary)
                                                }
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        case .failure:
                                            Rectangle()
                                                .fill(Color.surfacePrimary)
                                                .overlay {
                                                    Text(user.displayName.prefix(1))
                                                        .font(.system(size: 32))
                                                        .foregroundStyle(Color.accentPrimary)
                                                }
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    Text(user.displayName.prefix(1))
                                        .font(.system(size: 32))
                                        .foregroundStyle(Color.accentPrimary)
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                    .strokeBorder(Color.border, lineWidth: 1)
                            )
                            
                            Text(user.displayName)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            Text(user.status.displayName)
                                .font(AppFont.uiCaption)
                                .foregroundStyle(Color.accentPrimary)
                        }
                        
                        if showingMessageInput {
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("Message")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textPrimary)
                                
                                TextField("Write a friendly message...", text: $message, axis: .vertical)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(AppFont.body)
                                    .padding(AppLayout.spacing)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                                    )
                                    .lineLimit(4...8)
                                
                                HStack(spacing: AppLayout.spacing) {
                                    Button {
                                        onSendRequest(message.isEmpty ? nil : message)
                                        dismiss()
                                    } label: {
                                        Text("Send")
                                            .font(AppFont.monoCTA)
                                            .foregroundStyle(Color.bgPrimary)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.accentPrimary)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Button {
                                        showingMessageInput = false
                                    } label: {
                                        Text(String(localized: "common_cancel"))
                                            .font(AppFont.monoBody)
                                            .foregroundStyle(Color.textSecondary)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(Color.border, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        } else {
                            Button {
                                showingMessageInput = true
                            } label: {
                                Text("Say Hello")
                                    .font(AppFont.monoCTA)
                                    .foregroundStyle(Color.bgPrimary)
                                    .padding(.vertical, 12)
                                    .frame(width: 200)
                                    .background(Color.accentPrimary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}

// MARK: - Report Sheet

struct ReportSheet: View {
    let onSubmit: (ReportReason, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason = .harassment
    @State private var details = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Report")
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppLayout.spacingXL) {
                        // Reason Selection
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("What's the issue?")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            ForEach(ReportReason.allCases, id: \.self) { reason in
                                Button {
                                    selectedReason = reason
                                } label: {
                                    HStack {
                                        Text(reason.displayName)
                                            .font(AppFont.body)
                                            .foregroundStyle(selectedReason == reason ? .white : Color.textPrimary)
                                        Spacer()
                                        if selectedReason == reason {
                                            Image("checkmark")
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(AppLayout.spacing)
                                    .background(selectedReason == reason ? Color.accentPrimary : Color.bgPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous).strokeBorder(selectedReason == reason ? Color.accentPrimary : Color.borderPrimary, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // Details
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("More details")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            TextField("Tell us more...", text: $details, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(AppFont.body)
                                .padding(AppLayout.spacing)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                                )
                                .lineLimit(4...6)
                        }
                        
                        // Submit
                        Button {
                            onSubmit(selectedReason, details)
                            dismiss()
                        } label: {
                            Text("Submit Report")
                                .font(AppFont.monoCTA)
                                .foregroundStyle(Color.bgPrimary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.stateError)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}
