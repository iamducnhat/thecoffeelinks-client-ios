//
//  ConnectView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import CachedAsyncImage // CHANGED

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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Header
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text("Connect")
                            .font(AppFont.displayTitle)
                            .foregroundColor(Color.textInk)
                            .padding(.top, AppLayout.spacing)
                        
                        Text("Find friends at your local coffee shop")
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
                    
                    LazyVStack(spacing: AppLayout.spacingXL) {
                        if viewModel.isCheckedIn {
                            // Active Check-In Status
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("Currently at")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textInk)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(storesViewModel.selectedStore?.name ?? "Unknown")
                                            .font(AppFont.headline)
                                            .foregroundStyle(Color.textInk)
                                        Text(viewModel.currentMode.displayName)
                                            .font(AppFont.uiCaption)
                                            .foregroundStyle(Color.textMuted)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        Task { await viewModel.checkOut() }
                                    } label: {
                                        Text("Leave")
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
                                
                                Button {
                                    showingModeSelector = true
                                } label: {
                                    Text("Change status")
                                        .font(AppFont.body)
                                        .foregroundStyle(Color.primaryEspresso)
                                }
                            }
                            .padding(.horizontal, AppLayout.spacing)
                            
                            // Nearby People
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("People here")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textInk)
                                
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
                                    .background(Color.backgroundPaper)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                            .stroke(Color.border, lineWidth: 1)
                                    )
                                } else {
                                    VStack(spacing: AppLayout.spacing) {
                                        Text("No one nearby")
                                            .font(AppFont.sectionHeader)
                                            .foregroundStyle(Color.textInk)
                                        
                                        Text("Be the first to check in!")
                                            .font(AppFont.body)
                                            .foregroundStyle(Color.textMuted)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                            .stroke(Color.border, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                                    )
                                }
                            }
                            .padding(.horizontal, AppLayout.spacing)
                        } else {
                            // Offline Prompt
                            VStack(spacing: AppLayout.spacingXL) {
                                Text("Connect with people")
                                    .font(AppFont.displayTitle)
                                    .foregroundStyle(Color.textInk)
                                
                                Text("Check in to a coffee shop to see who else is there and start a conversation.")
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Button {
                                    showingStoreSelector = true
                                } label: {
                                    Text("Check In")
                                        .font(AppFont.monoCTA)
                                        .foregroundStyle(Color.backgroundPaper)
                                        .padding(.horizontal, 48)
                                        .padding(.vertical, 12)
                                        .background(Color.accentColor)
                                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                                }
                            }
                            .padding(.vertical, 60)
                        }
                        
                        // Privacy & Safety
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Privacy & Safety")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            VStack(spacing: 0) {
                                ActionRow(title: "Block users", icon: "person.crop.circle.badge.xmark") { }
                                ActionRow(title: "Report a concern", icon: "exclamationmark.triangle") { showingReport = true }
                            }
                            .background(Color.surfaceCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, lineWidth: 1)
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
                        .fill(Color.surfaceCard)
                        .frame(width: 44, height: 44)
                    
                    if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
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
                                        Text(user.displayName.prefix(1)) // CHANGED
                                            .font(AppFont.body) // CHANGED
                                            .foregroundStyle(Color.primaryEspresso) // CHANGED
                                    } // CHANGED
                            @unknown default: // CHANGED
                                EmptyView() // CHANGED
                            } // CHANGED
                        } // CHANGED
                    } else {
                        Text(user.displayName.prefix(1))
                            .font(AppFont.body)
                            .foregroundStyle(Color.primaryEspresso)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(Color.border, lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(AppFont.body)
                        .foregroundStyle(Color.textInk)
                    Text(user.status.displayName)
                        .font(AppFont.uiMicro)
                        .foregroundStyle(Color.textMuted)
                }
                
                Spacer()
                
                if user.mode == .open {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.primaryEspresso)
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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Check In")
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textInk)
                    }
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppLayout.spacingXL) {
                        // Location
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Location")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            Text(storeName ?? "Unknown")
                                .font(AppFont.headline)
                                .foregroundStyle(Color.textInk)
                                .padding(AppLayout.spacing)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surfaceCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.border, lineWidth: 1)
                                )
                        }
                        
                        // Visibility Mode
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Visibility")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            ForEach(ConnectionMode.allCases, id: \.self) { mode in
                                Button {
                                    selectedMode = mode
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(mode.displayName)
                                                .font(AppFont.body)
                                                .foregroundStyle(Color.textInk)
                                            Text(mode.description)
                                                .font(AppFont.uiMicro)
                                                .foregroundStyle(Color.textMuted)
                                        }
                                        Spacer()
                                        if selectedMode == mode {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Color.primaryEspresso)
                                        }
                                    }
                                    .padding(AppLayout.spacing)
                                    .background(selectedMode == mode ? Color.primaryEspresso.opacity(0.1) : Color.backgroundPaper)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                            .stroke(selectedMode == mode ? Color.primaryEspresso : Color.border, lineWidth: 1)
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
    }
}

// MARK: - Mode Sheet

struct ModeSheet: View {
    let currentMode: ConnectionMode
    let onSelect: (ConnectionMode) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Change Status")
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textInk)
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
                                        .foregroundStyle(Color.textInk)
                                    Spacer()
                                    if currentMode == mode {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.primaryEspresso)
                                    }
                                }
                                .padding(AppLayout.spacing)
                                .background(currentMode == mode ? Color.primaryEspresso.opacity(0.1) : Color.backgroundPaper)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(currentMode == mode ? Color.primaryEspresso : Color.border, lineWidth: 1)
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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textInk)
                    }
                }
                .padding(AppLayout.spacing)
                
                ScrollView {
                    VStack(spacing: AppLayout.spacingXL) {
                        // Avatar & Info
                        VStack(spacing: AppLayout.spacing) {
                            ZStack {
                                Rectangle()
                                    .fill(Color.surfaceCard)
                                    .frame(width: 100, height: 100)
                                
                                if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
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
                                                    Text(user.displayName.prefix(1)) // CHANGED
                                                        .font(.system(size: 32)) // CHANGED
                                                        .foregroundStyle(Color.primaryEspresso) // CHANGED
                                                } // CHANGED
                                        @unknown default: // CHANGED
                                            EmptyView() // CHANGED
                                        } // CHANGED
                                    } // CHANGED
                                } else {
                                    Text(user.displayName.prefix(1))
                                        .font(.system(size: 32))
                                        .foregroundStyle(Color.primaryEspresso)
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                            
                            Text(user.displayName)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            Text(user.status.displayName)
                                .font(AppFont.uiCaption)
                                .foregroundStyle(Color.primaryEspresso)
                        }
                        
                        if showingMessageInput {
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("Message")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textInk)
                                
                                TextField("Write a friendly message...", text: $message, axis: .vertical)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(AppFont.body)
                                    .padding(AppLayout.spacing)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                            .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                                    )
                                    .lineLimit(4...8)
                                
                                HStack(spacing: AppLayout.spacing) {
                                    Button {
                                        onSendRequest(message.isEmpty ? nil : message)
                                        dismiss()
                                    } label: {
                                        Text("Send")
                                            .font(AppFont.monoCTA)
                                            .foregroundStyle(Color.backgroundPaper)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.accentColor)
                                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                                    }
                                    
                                    Button {
                                        showingMessageInput = false
                                    } label: {
                                        Text("Cancel")
                                            .font(AppFont.monoBody)
                                            .foregroundStyle(Color.textMuted)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                                    .stroke(Color.border, lineWidth: 1)
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
                                    .foregroundStyle(Color.backgroundPaper)
                                    .padding(.vertical, 12)
                                    .frame(width: 200)
                                    .background(Color.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Report")
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textInk)
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
                                .foregroundStyle(Color.textInk)
                            
                            ForEach(ReportReason.allCases, id: \.self) { reason in
                                Button {
                                    selectedReason = reason
                                } label: {
                                    HStack {
                                        Text(reason.displayName)
                                            .font(AppFont.body)
                                            .foregroundStyle(Color.textInk)
                                        Spacer()
                                        if selectedReason == reason {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Color.primaryEspresso)
                                        }
                                    }
                                    .padding(AppLayout.spacing)
                                    .background(selectedReason == reason ? Color.primaryEspresso.opacity(0.1) : Color.backgroundPaper)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                            .stroke(selectedReason == reason ? Color.primaryEspresso : Color.border, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // Details
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("More details")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            TextField("Tell us more...", text: $details, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(AppFont.body)
                                .padding(AppLayout.spacing)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
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
                                .foregroundStyle(Color.backgroundPaper)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.semanticError)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}
