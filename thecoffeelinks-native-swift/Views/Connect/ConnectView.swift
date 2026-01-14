//
//  ConnectView.swift
//  thecoffeelinks-native-swift
//
//  Main Connect/Networking view - Production Ready
//

import SwiftUI

struct ConnectView: View {
    @StateObject private var viewModel = ConnectViewModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedUser: EnhancedCheckIn?
    @State private var showTreatSheet = false
    @State private var showReportSheet = false
    @State private var userToReport: String?
    @State private var showStoreSelector = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with Status Toggle
                    header
                    
                    // Main Content
                    if !viewModel.isCheckedIn {
                        notCheckedInState
                    } else {
                        checkedInContent
                    }
                }
                
                // Undo Toast
                if let undoAction = viewModel.undoAction {
                    VStack {
                        Spacer()
                        undoToast(undoAction)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: viewModel.undoAction != nil)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .task {
                await viewModel.fetchBlockedUsers()
                if viewModel.isCheckedIn {
                    await viewModel.refresh()
                }
            }
            .sheet(item: $selectedUser) { user in
                UserProfileSheet(
                    user: user,
                    connectionStatus: viewModel.connectionStatuses[user.userId] ?? .none,
                    onConnect: { message in
                        Task {
                            _ = await viewModel.sendConnectionRequest(to: user.userId, message: message)
                        }
                    },
                    onTreat: {
                        selectedUser = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showTreatSheet = true
                        }
                    },
                    onBlock: {
                        Task { await viewModel.blockUser(user.userId) }
                        selectedUser = nil
                    },
                    onReport: {
                        userToReport = user.userId
                        selectedUser = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showReportSheet = true
                        }
                    }
                )
            }
            .sheet(isPresented: $showTreatSheet) {
                if let user = selectedUser {
                    CoffeeTreatSheet(
                        recipientName: user.user?.displayName ?? "Coffee Lover",
                        recipientId: user.userId,
                        onSend: { productId, productName, message in
                            Task {
                                _ = await viewModel.sendCoffeeTreat(
                                    to: user.userId,
                                    productId: productId,
                                    productName: productName,
                                    message: message
                                )
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showReportSheet) {
                if let userId = userToReport {
                    ReportSheet(userId: userId) { reason, details in
                        Task {
                            await viewModel.reportUser(userId, reason: reason, details: details)
                        }
                    }
                }
            }
            .sheet(isPresented: $showStoreSelector) {
                StoreSelectionSheet { storeId in
                    Task { await viewModel.checkIn(storeId: storeId) }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - Header
    
    var header: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Connect")
                    .font(.brandSerif(32))
                    .foregroundStyle(Color.brandPrimary)
                
                Spacer()
                
                if viewModel.isCheckedIn {
                    // Check-out button
                    Button {
                        Task { await viewModel.checkOut() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Leave")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
            
            // Presence Status Toggle (only when checked in)
            if viewModel.isCheckedIn {
                presenceToggle
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    var presenceToggle: some View {
        HStack(spacing: 0) {
            ForEach(PresenceStatus.allCases, id: \.self) { status in
                Button {
                    Task { await viewModel.updatePresenceStatus(status) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: status.icon)
                        Text(status.displayName)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(viewModel.presenceStatus == status ? .white : Color.coffeeDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.presenceStatus == status
                        ? Color.forestCanopy
                        : Color.clear
                    )
                }
            }
        }
        .background(Color.neutral100)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: viewModel.presenceStatus)
    }
    
    // MARK: - Not Checked In State
    
    var notCheckedInState: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Illustration
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(Color.brandAccent.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("Check in to Connect")
                    .font(.brandSerif(28))
                    .foregroundStyle(Color.coffeeDark)
                
                Text("Visit a Coffee Links location and check in to discover who's around and open to networking.")
                    .font(.brandSans(16))
                    .foregroundStyle(Color.neutral600)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Check-in Button
            Button {
                showStoreSelector = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                    Text("Check In")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.forestCanopy)
                .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            
            // Privacy Note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(Color.neutral500)
                Text("You control your visibility. Default is Focus Mode.")
                    .font(.caption)
                    .foregroundStyle(Color.neutral500)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Checked In Content
    
    var checkedInContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Focus Mode Banner
                if viewModel.presenceStatus == .focusMode {
                    focusModeBanner
                }
                
                // Pending Requests Section
                if !viewModel.pendingRequests.isEmpty {
                    pendingRequestsSection
                }
                
                // Pending Coffee Treats
                if !viewModel.pendingTreats.isEmpty {
                    pendingTreatsSection
                }
                
                // Rate Limit Warning
                if viewModel.isRateLimited {
                    rateLimitBanner
                } else if viewModel.requestsRemaining <= 3 {
                    lowRequestsBanner
                }
                
                // Discoverable Users (only in Open mode)
                if viewModel.presenceStatus == .openToNetwork {
                    discoverSection
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Focus Mode Banner
    
    var focusModeBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.fill")
                .font(.title3)
                .foregroundStyle(Color.brandAccent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Focus Mode Active")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.coffeeDark)
                Text("You're invisible to others. Toggle to Open to Network to be discoverable.")
                    .font(.caption)
                    .foregroundStyle(Color.neutral600)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.brandAccent.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Pending Requests Section
    
    var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Connection Requests")
                    .font(.brandSerif(20))
                    .foregroundStyle(Color.coffeeDark)
                
                Text("\(viewModel.pendingRequests.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandAccent)
                    .clipShape(Capsule())
            }
            
            ForEach(viewModel.pendingRequests) { request in
                ConnectionRequestCard(
                    request: request,
                    onAccept: {
                        Task {
                            await viewModel.respondToRequest(
                                request.id,
                                accept: true,
                                userId: request.fromUserId
                            )
                        }
                    },
                    onDecline: {
                        Task {
                            await viewModel.respondToRequest(
                                request.id,
                                accept: false,
                                userId: request.fromUserId
                            )
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Pending Treats Section
    
    var pendingTreatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("☕ Someone's buying!")
                    .font(.brandSerif(20))
                    .foregroundStyle(Color.coffeeDark)
            }
            
            ForEach(viewModel.pendingTreats) { treat in
                CoffeeTreatCard(
                    treat: treat,
                    onAccept: {
                        Task { await viewModel.respondToTreat(treat.id, accept: true) }
                    },
                    onDecline: {
                        Task { await viewModel.respondToTreat(treat.id, accept: false) }
                    }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Rate Limit Banners
    
    var rateLimitBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.title3)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Slow Down")
                    .font(.subheadline.weight(.semibold))
                Text("You've reached the limit of connection requests. Try again later.")
                    .font(.caption)
                    .foregroundStyle(Color.neutral600)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    var lowRequestsBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.neutral500)
            Text("\(viewModel.requestsRemaining) connection requests remaining this hour")
                .font(.caption)
                .foregroundStyle(Color.neutral500)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Discover Section
    
    var discoverSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Here Now")
                    .font(.brandSerif(20))
                    .foregroundStyle(Color.coffeeDark)
                
                Spacer()
                
                if viewModel.isLoadingUsers {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            
            if viewModel.isLoadingUsers && viewModel.filteredDiscoverableUsers.isEmpty {
                // Skeleton Loading (NO spinners per requirement)
                ForEach(0..<3, id: \.self) { _ in
                    DiscoverUserSkeleton()
                }
            } else if viewModel.filteredDiscoverableUsers.isEmpty {
                emptyDiscoverState
            } else {
                ForEach(viewModel.filteredDiscoverableUsers) { checkIn in
                    DiscoverUserCard(
                        checkIn: checkIn,
                        connectionStatus: viewModel.connectionStatuses[checkIn.userId] ?? .none,
                        onTap: { selectedUser = checkIn },
                        onConnect: {
                            Task {
                                _ = await viewModel.sendConnectionRequest(to: checkIn.userId)
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    var emptyDiscoverState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.neutral400)
            
            Text("No one's here yet")
                .font(.brandSans(16).weight(.medium))
                .foregroundStyle(Color.neutral600)
            
            Text("Be the first to connect! Others will see you when they check in.")
                .font(.caption)
                .foregroundStyle(Color.neutral500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Undo Toast
    
    func undoToast(_ action: UndoableAction) -> some View {
        HStack {
            Text(action.description)
                .font(.subheadline)
                .foregroundStyle(.white)
            
            Spacer()
            
            Button("Undo") {
                viewModel.performUndo()
            }
            .font(.subheadline.bold())
            .foregroundStyle(Color.brandAccent)
        }
        .padding()
        .background(Color.coffeeDark)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Discover User Card

struct DiscoverUserCard: View {
    let checkIn: EnhancedCheckIn
    let connectionStatus: ConnectionStatus
    let onTap: () -> Void
    let onConnect: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                avatarView
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(checkIn.user?.displayName ?? "Coffee Lover")
                        .font(.brandSans(16).weight(.semibold))
                        .foregroundStyle(Color.coffeeDark)
                    
                    if let headline = checkIn.user?.headline, !headline.isEmpty {
                        Text(headline)
                            .font(.caption)
                            .foregroundStyle(Color.neutral600)
                            .lineLimit(1)
                    }
                    
                    // Intent Tags
                    if let intents = checkIn.user?.intents, !intents.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(intents.prefix(2)) { intent in
                                IntentTag(intent: intent)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Action Button
                connectionButton
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    var avatarView: some View {
        Group {
            if let avatarUrl = checkIn.user?.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
    }
    
    var initialsView: some View {
        Circle()
            .fill(Color.forestCanopy)
            .overlay {
                Text(checkIn.user?.initials ?? "?")
                    .font(.brandSerif(20))
                    .foregroundStyle(.white)
            }
    }
    
    @ViewBuilder
    var connectionButton: some View {
        switch connectionStatus {
        case .none:
            Button(action: onConnect) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.forestCanopy)
                    .padding(12)
                    .background(Color.forestCanopy.opacity(0.1))
                    .clipShape(Circle())
            }
        case .pending:
            Image(systemName: "clock.fill")
                .font(.system(size: 16))
                .foregroundStyle(.orange)
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .clipShape(Circle())
        case .accepted:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.green)
                .padding(12)
                .background(Color.green.opacity(0.1))
                .clipShape(Circle())
        case .declined, .blocked:
            EmptyView()
        }
    }
}

// MARK: - Intent Tag

struct IntentTag: View {
    let intent: NetworkingIntent
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: intent.icon)
                .font(.system(size: 10))
            Text(intent.displayName)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(tagColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tagColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    var tagColor: Color {
        switch intent {
        case .mentor: return .yellow
        case .hiring: return .blue
        case .sales: return .green
        case .learn: return .purple
        case .collaborate: return .orange
        case .justCoffee: return .brown
        }
    }
}

// MARK: - Skeleton Loading

struct DiscoverUserSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.neutral200)
                .frame(width: 56, height: 56)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.neutral200)
                    .frame(width: 120, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.neutral100)
                    .frame(width: 180, height: 12)
            }
            
            Spacer()
            
            Circle()
                .fill(Color.neutral200)
                .frame(width: 44, height: 44)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Connection Request Card

struct ConnectionRequestCard: View {
    let request: ConnectionRequest
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.forestCanopy)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(request.fromUser?.initials ?? "?")
                        .font(.brandSerif(18))
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.fromUser?.displayName ?? "Someone")
                    .font(.subheadline.weight(.semibold))
                
                if let msg = request.message {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(Color.neutral600)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.red)
                        .padding(10)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                        .padding(10)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Coffee Treat Card

struct CoffeeTreatCard: View {
    let treat: CoffeeTreat
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("☕")
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(treat.fromUser?.displayName ?? "Someone") wants to buy you a \(treat.productName)!")
                        .font(.subheadline.weight(.semibold))
                    
                    if let msg = treat.message {
                        Text("\"\(msg)\"")
                            .font(.caption)
                            .foregroundStyle(Color.neutral600)
                            .italic()
                    }
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.neutral600)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.neutral100)
                        .cornerRadius(12)
                }
                
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.forestCanopy)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.sunRay.opacity(0.2))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    ConnectView()
        .environmentObject(AppState())
}
