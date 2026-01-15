//
//  ConnectionComponents.swift
//  thecoffeelinks-native-swift
//
//  UI components for connection: Focus/Open toggle, Block/Report sheet
//

import SwiftUI

// MARK: - Connection Mode Toggle

struct ConnectionModeToggle: View {
    @ObservedObject private var connectionService = ConnectionService.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: connectionService.connectionMode.iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(connectionService.isOpenToConnect ? Color.forestCanopy : Color.neutral400)
                    .frame(width: 44, height: 44)
                    .background(connectionService.isOpenToConnect ? Color.forestCanopy.opacity(0.1) : Color.neutral100)
                    .clipShape(Circle())
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(connectionService.connectionMode.displayTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.coffeeDark)
                    
                    Text(connectionService.connectionMode.displaySubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.neutral500)
                }
                
                Spacer()
                
                // Toggle
                Toggle("", isOn: $connectionService.isOpenToConnect)
                    .labelsHidden()
                    .tint(Color.forestCanopy)
            }
            
            // Safety reminder when turning on
            if connectionService.isOpenToConnect {
                HStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 10))
                    Text("Only your name is visible. Block anyone anytime.")
                        .font(.caption2)
                }
                .foregroundStyle(Color.forestCanopy)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color.forestCanopy.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Block/Report Sheet

struct BlockReportSheet: View {
    let userId: String
    let userName: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var connectionService = ConnectionService.shared
    
    @State private var selectedReason: BlockReason?
    @State private var isReporting = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "shield.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.red)
                    
                    Text("Block \(userName)?")
                        .font(.headline)
                    
                    Text("They won't be able to see you or interact with you.")
                        .font(.caption)
                        .foregroundStyle(Color.neutral500)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                Divider()
                
                // Quick Block (no reason needed)
                Button {
                    connectionService.blockUser(userId: userId, reason: nil)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                        Text("Block")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Report (requires reason)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Report & Block")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.coffeeDark)
                    
                    Text("Help us keep the community safe")
                        .font(.caption)
                        .foregroundStyle(Color.neutral500)
                    
                    ForEach(BlockReason.allCases, id: \.self) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedReason == reason ? Color.red : Color.neutral400)
                                
                                Text(reason.displayText)
                                    .foregroundStyle(Color.coffeeDark)
                                
                                Spacer()
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    
                    // Submit Report
                    Button {
                        guard let reason = selectedReason else { return }
                        isReporting = true
                        connectionService.reportUser(userId: userId, reason: reason)
                        dismiss()
                    } label: {
                        HStack {
                            if isReporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "flag.fill")
                                Text("Report & Block")
                            }
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedReason == nil ? Color.neutral300 : Color.red)
                        .cornerRadius(12)
                    }
                    .disabled(selectedReason == nil)
                }
                .padding()
                .background(Color.neutral50)
                .cornerRadius(16)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Block or Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Mute Toggle (for connected users)

struct MuteUserToggle: View {
    let userId: String
    @ObservedObject private var connectionService = ConnectionService.shared
    
    var isMuted: Bool {
        connectionService.mutedUserIds.contains(userId)
    }
    
    var body: some View {
        Button {
            if isMuted {
                connectionService.unmuteUser(userId: userId)
            } else {
                connectionService.muteUser(userId: userId)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isMuted ? "bell.slash.fill" : "bell.fill")
                    .font(.system(size: 12))
                Text(isMuted ? "Muted" : "Mute")
                    .font(.caption)
            }
            .foregroundStyle(isMuted ? Color.neutral500 : Color.coffeeDark)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isMuted ? Color.neutral100 : Color.neutral50)
            .cornerRadius(8)
        }
    }
}

// MARK: - User Profile Actions (Block/Report/Mute row)

struct UserProfileActions: View {
    let userId: String
    let userName: String
    let isConnected: Bool
    
    @State private var showBlockSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            if isConnected {
                MuteUserToggle(userId: userId)
            }
            
            Button {
                showBlockSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "hand.raised")
                        .font(.system(size: 12))
                    Text("Block")
                        .font(.caption)
                }
                .foregroundStyle(Color.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showBlockSheet) {
            BlockReportSheet(userId: userId, userName: userName)
        }
    }
}

// MARK: - Open to Connect Indicator (on avatar)

struct ConnectionIndicator: View {
    @ObservedObject private var connectionService = ConnectionService.shared
    
    var body: some View {
        if connectionService.isOpenToConnect {
            Circle()
                .fill(Color.forestCanopy)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
    }
}

// MARK: - Presence Signal for Home

struct PresenceSignalView: View {
    let connectedNames: [String]
    let regularsCount: Int
    
    var body: some View {
        if regularsCount > 0 || !connectedNames.isEmpty {
            HStack(spacing: 10) {
                // Indicator dot
                Circle()
                    .fill(Color.forestCanopy)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let firstName = connectedNames.first {
                        Text("\(firstName) is here")
                            .font(.caption.bold())
                            .foregroundStyle(Color.forestCanopy)
                    }
                    
                    if regularsCount > 0 {
                        Text("\(regularsCount) regulars at this store")
                            .font(.caption)
                            .foregroundStyle(Color.neutral500)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color.forestCanopy.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

// MARK: - Previews

#Preview("Connection Toggle") {
    VStack {
        ConnectionModeToggle()
            .padding()
        Spacer()
    }
    .background(Color.brandBackground)
}

#Preview("Block Sheet") {
    BlockReportSheet(userId: "123", userName: "John Doe")
}
