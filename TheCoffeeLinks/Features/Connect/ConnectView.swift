//
//  ConnectView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
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
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    VStack(spacing: BaseViewLayout.lg) {
                        AppSectionHeader(
                            title: String(localized: "network_connect_action"),
                            subtitle: "Find friends at your local coffee shop"
                        )
                        .padding(.horizontal, BaseViewLayout.screenPadding)
                        
                        Divider().background(BaseViewColor.borderSecondary)
                    }
                    .padding(.top, BaseViewLayout.sm)
                    .background(BaseViewColor.background)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    LazyVStack(spacing: BaseViewLayout.spacingXL) {
                        if viewModel.isCheckedIn {
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                                Text("Currently at")
                                    .textCase(.uppercase)
                                    .font(BaseViewFont.sectionHeader)
                                    .foregroundStyle(BaseViewColor.textPrimary)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(storesViewModel.selectedStore?.name ?? "Unknown")
                                            .font(BaseViewFont.headline)
                                            .foregroundStyle(BaseViewColor.textPrimary)
                                        Text(viewModel.currentMode.displayName)
                                            .font(BaseViewFont.uiCaption)
                                            .foregroundStyle(BaseViewColor.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        Task { await viewModel.checkOut() }
                                    } label: {
                                        Text("Leave")
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
                                .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                                        .strokeBorder(BaseViewColor.accent, lineWidth: 1)
                                )
                                
                                Button {
                                    showingModeSelector = true
                                } label: {
                                    Text("Change status")
                                        .font(BaseViewFont.body)
                                        .foregroundStyle(BaseViewColor.accent)
                                }
                            }
                            .padding(.horizontal, BaseViewLayout.spacing)
                            
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                                Text("People here")
                                    .textCase(.uppercase)
                                    .font(BaseViewFont.sectionHeader)
                                    .foregroundStyle(BaseViewColor.textPrimary)
                                
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
                                    .background(BaseViewColor.background)
                                    .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                                            .strokeBorder(BaseViewColor.border, lineWidth: 1)
                                    )
                                } else {
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
                                    .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                                            .strokeBorder(BaseViewColor.border, style: StrokeStyle(lineWidth: 1, dash: BaseViewLayout.dashedPattern))
                                    )
                                }
                            }
                            .padding(.horizontal, BaseViewLayout.spacing)
                        } else {
                            VStack(spacing: BaseViewLayout.spacingXL) {
                                Text("Connect with people")
                                    .font(BaseViewFont.displayTitle)
                                    .foregroundStyle(BaseViewColor.textPrimary)
                                
                                Text("Check in to a coffee shop to see who else is there and start a conversation.")
                                    .font(BaseViewFont.body)
                                    .foregroundStyle(BaseViewColor.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Button {
                                    showingStoreSelector = true
                                } label: {
                                    Text(String(localized: "network_check_in_action"))
                                        .font(BaseViewFont.monoCTA)
                                        .foregroundStyle(BaseViewColor.background)
                                        .padding(.horizontal, 48)
                                        .padding(.vertical, 12)
                                        .background(BaseViewColor.accent)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 60)
                        }
                        
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text("Privacy & Safety")
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            VStack(spacing: 0) {
                                ProfileRow(title: "Block users", icon: "circle_x") { }
                                ProfileRow(title: "Report a concern", icon: "triangle_alert") { showingReport = true }
                            }
                            .background(BaseViewColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, BaseViewLayout.spacing)
                    }
                    .padding(.top, BaseViewLayout.spacing)
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
            HStack(spacing: BaseViewLayout.spacing) {
                AppRemoteImage(
                    url: URL(string: user.avatarUrl ?? ""),
                    width: 44,
                    height: 44,
                    cornerRadius: BaseViewLayout.radiusMedium,
                    backgroundColor: BaseViewColor.surface,
                    borderColor: BaseViewColor.border,
                    showsProgress: true,
                    placeholderIcon: nil,
                    placeholderText: String(user.displayName.prefix(1))
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(BaseViewFont.body)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    Text(user.status.displayName)
                        .font(BaseViewFont.uiMicro)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
                
                Spacer()
                
                if user.mode == .open {
                    Image("message_circle")
                        .font(.system(size: 12))
                        .foregroundStyle(BaseViewColor.accent)
                }
            }
            .padding(BaseViewLayout.spacing)
        }
        .buttonStyle(.plain)
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
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(String(localized: "network_check_in_action"))
                        .font(BaseViewFont.displayTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    
                    Spacer()
                    
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(BaseViewFont.navIcon)
                            .foregroundStyle(BaseViewColor.textPrimary)
                    }
                }
                .padding(BaseViewLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: BaseViewLayout.spacingXL) {
                        // Location
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text(String(localized: "common_location"))
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            Text(storeName ?? "Unknown")
                                .font(BaseViewFont.headline)
                                .foregroundStyle(BaseViewColor.textPrimary)
                                .padding(BaseViewLayout.spacing)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BaseViewColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                                        .strokeBorder(BaseViewColor.border, lineWidth: 1)
                                )
                        }
                        
                        // Visibility Mode
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text("Visibility")
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            ForEach(ConnectionMode.allCases, id: \.self) { mode in
                                Button {
                                    selectedMode = mode
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(mode.displayName)
                                                .font(BaseViewFont.body)
                                                .foregroundStyle(selectedMode == mode ? .white : BaseViewColor.textPrimary)
                                            Text(mode.description)
                                                .font(BaseViewFont.uiMicro)
                                                .foregroundStyle(selectedMode == mode ? .white : BaseViewColor.textSecondary)
                                        }
                                        Spacer()
                                        if selectedMode == mode {
                                            Image("checkmark")
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(BaseViewLayout.spacing)
                                    .background(selectedMode == mode ? BaseViewColor.accent : BaseViewColor.background)
                                    .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
        .overlay(
                                        RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous).strokeBorder(selectedMode == mode ? BaseViewColor.accent : BaseViewColor.border, lineWidth: 1)
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
    }
}

// MARK: - Mode Sheet

struct ModeSheet: View {
    let currentMode: ConnectionMode
    let onSelect: (ConnectionMode) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Change Status")
                        .font(BaseViewFont.displayTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    
                    Spacer()
                    
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(BaseViewFont.navIcon)
                            .foregroundStyle(BaseViewColor.textPrimary)
                    }
                }
                .padding(BaseViewLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    LazyVStack(spacing: BaseViewLayout.spacing) {
                        ForEach(ConnectionMode.allCases, id: \.self) { mode in
                            Button {
                                onSelect(mode)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(mode.displayName)
                                        .font(BaseViewFont.body)
                                        .foregroundStyle(currentMode == mode ? .white : BaseViewColor.textPrimary)
                                    Spacer()
                                    if currentMode == mode {
                                        Image("checkmark")
                                            .foregroundStyle(.white)
                                    }
                                }
                                .padding(BaseViewLayout.spacing)
                                .background(currentMode == mode ? BaseViewColor.accent : BaseViewColor.background)
                                .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
        .overlay(
                                    RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous).strokeBorder(currentMode == mode ? BaseViewColor.accent : BaseViewColor.border, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(BaseViewLayout.spacing)
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
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(BaseViewFont.navIcon)
                            .foregroundStyle(BaseViewColor.textPrimary)
                    }
                }
                .padding(BaseViewLayout.spacing)
                
                ScrollView {
                    VStack(spacing: BaseViewLayout.spacingXL) {
                        // Avatar & Info
                        VStack(spacing: BaseViewLayout.spacing) {
                            AppRemoteImage(
                                url: URL(string: user.avatarUrl ?? ""),
                                width: 100,
                                height: 100,
                                cornerRadius: BaseViewLayout.radiusMedium,
                                backgroundColor: BaseViewColor.surface,
                                borderColor: BaseViewColor.border,
                                showsProgress: true,
                                placeholderIcon: nil,
                                placeholderText: String(user.displayName.prefix(1))
                            )
                            
                            Text(user.displayName)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            Text(user.status.displayName)
                                .font(BaseViewFont.uiCaption)
                                .foregroundStyle(BaseViewColor.accent)
                        }
                        
                        if showingMessageInput {
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                                Text("Message")
                                    .textCase(.uppercase)
                                    .font(BaseViewFont.sectionHeader)
                                    .foregroundStyle(BaseViewColor.textPrimary)
                                
                                TextField("Write a friendly message...", text: $message, axis: .vertical)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(BaseViewFont.body)
                                    .padding(BaseViewLayout.spacing)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(BaseViewColor.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: BaseViewLayout.dashedPattern))
                                    )
                                    .lineLimit(4...8)
                                
                                HStack(spacing: BaseViewLayout.spacing) {
                                    Button {
                                        onSendRequest(message.isEmpty ? nil : message)
                                        dismiss()
                                    } label: {
                                        Text("Send")
                                            .font(BaseViewFont.monoCTA)
                                            .foregroundStyle(BaseViewColor.background)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(BaseViewColor.accent)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Button {
                                        showingMessageInput = false
                                    } label: {
                                        Text(String(localized: "common_cancel"))
                                            .font(BaseViewFont.monoBody)
                                            .foregroundStyle(BaseViewColor.textSecondary)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        } else {
                            Button {
                                showingMessageInput = true
                            } label: {
                                Text("Say Hello")
                                    .font(BaseViewFont.monoCTA)
                                    .foregroundStyle(BaseViewColor.background)
                                    .padding(.vertical, 12)
                                    .frame(width: 200)
                                    .background(BaseViewColor.accent)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(BaseViewLayout.spacing)
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
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Report")
                        .font(BaseViewFont.displayTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    
                    Spacer()
                    
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(BaseViewFont.navIcon)
                            .foregroundStyle(BaseViewColor.textPrimary)
                    }
                }
                .padding(BaseViewLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: BaseViewLayout.spacingXL) {
                        // Reason Selection
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text("What's the issue?")
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            ForEach(ReportReason.allCases, id: \.self) { reason in
                                Button {
                                    selectedReason = reason
                                } label: {
                                    HStack {
                                        Text(reason.displayName)
                                            .font(BaseViewFont.body)
                                            .foregroundStyle(selectedReason == reason ? .white : BaseViewColor.textPrimary)
                                        Spacer()
                                        if selectedReason == reason {
                                            Image("checkmark")
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(BaseViewLayout.spacing)
                                    .background(selectedReason == reason ? BaseViewColor.accent : BaseViewColor.background)
                                    .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
        .overlay(
                                        RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous).strokeBorder(selectedReason == reason ? BaseViewColor.accent : BaseViewColor.border, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // Details
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text("More details")
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            TextField("Tell us more...", text: $details, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(BaseViewFont.body)
                                .padding(BaseViewLayout.spacing)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(BaseViewColor.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: BaseViewLayout.dashedPattern))
                                )
                                .lineLimit(4...6)
                        }
                        
                        // Submit
                        Button {
                            onSubmit(selectedReason, details)
                            dismiss()
                        } label: {
                            Text("Submit Report")
                                .font(BaseViewFont.monoCTA)
                                .foregroundStyle(BaseViewColor.background)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(BaseViewColor.semanticError)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(BaseViewLayout.spacing)
                }
            }
        }
    }
}
