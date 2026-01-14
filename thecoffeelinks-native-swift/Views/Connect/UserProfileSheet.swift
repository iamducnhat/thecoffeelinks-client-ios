//
//  UserProfileSheet.swift
//  thecoffeelinks-native-swift
//
//  Profile preview sheet for networking discovery
//

import SwiftUI

struct UserProfileSheet: View {
    let user: EnhancedCheckIn
    let connectionStatus: ConnectionStatus
    let onConnect: (String?) -> Void
    let onTreat: () -> Void
    let onBlock: () -> Void
    let onReport: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var connectionMessage = ""
    @State private var showConnectInput = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Intent Tags
                    if let intents = user.user?.intents, !intents.isEmpty {
                        intentSection(intents)
                    }
                    
                    // Bio
                    if let bio = user.user?.bio, !bio.isEmpty {
                        bioSection(bio)
                    }
                    
                    // Action Buttons
                    actionButtons
                    
                    // Safety Actions
                    safetyActions
                }
                .padding()
            }
            .background(Color.brandBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Profile Header
    
    var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            Group {
                if let avatarUrl = user.user?.avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        initialsView
                    }
                } else {
                    initialsView
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(user.user?.displayName ?? "Coffee Lover")
                        .font(.brandSerif(24))
                        .foregroundStyle(Color.coffeeDark)
                    
                    if user.user?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.blue)
                    }
                }
                
                if let headline = user.user?.headline, !headline.isEmpty {
                    Text(headline)
                        .font(.brandSans(16))
                        .foregroundStyle(Color.neutral600)
                }
                
                if let industry = user.user?.industry {
                    Text(industry)
                        .font(.caption)
                        .foregroundStyle(Color.brandAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.brandAccent.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            // Check-in Duration
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Here for \(user.durationMinutes) min")
                    .font(.caption)
            }
            .foregroundStyle(Color.neutral500)
        }
    }
    
    var initialsView: some View {
        Circle()
            .fill(Color.forestCanopy)
            .overlay {
                Text(user.user?.initials ?? "?")
                    .font(.brandSerif(36))
                    .foregroundStyle(.white)
            }
    }
    
    // MARK: - Intent Section
    
    func intentSection(_ intents: [NetworkingIntent]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Looking for")
                .font(.caption.bold())
                .foregroundStyle(Color.neutral500)
            
            FlowLayout(spacing: 8) {
                ForEach(intents) { intent in
                    HStack(spacing: 6) {
                        Image(systemName: intent.icon)
                        Text(intent.displayName)
                    }
                    .font(.subheadline)
                    .foregroundStyle(intentColor(intent))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(intentColor(intent).opacity(0.1))
                    .cornerRadius(20)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func intentColor(_ intent: NetworkingIntent) -> Color {
        switch intent {
        case .mentor: return .yellow
        case .hiring: return .blue
        case .sales: return .green
        case .learn: return .purple
        case .collaborate: return .orange
        case .justCoffee: return .brown
        }
    }
    
    // MARK: - Bio Section
    
    func bioSection(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.caption.bold())
                .foregroundStyle(Color.neutral500)
            
            Text(bio)
                .font(.brandSans(14))
                .foregroundStyle(Color.coffeeDark)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Action Buttons
    
    var actionButtons: some View {
        VStack(spacing: 12) {
            // Connect Button
            if connectionStatus == .none {
                if showConnectInput {
                    VStack(spacing: 12) {
                        TextField("Add a note (optional)", text: $connectionMessage)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                showConnectInput = false
                                connectionMessage = ""
                            }
                            .foregroundStyle(Color.neutral600)
                            
                            Button {
                                onConnect(connectionMessage.isEmpty ? nil : connectionMessage)
                                dismiss()
                            } label: {
                                Text("Send Request")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.forestCanopy)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.neutral100)
                    .cornerRadius(16)
                } else {
                    Button {
                        showConnectInput = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Connect")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.forestCanopy)
                        .cornerRadius(16)
                    }
                }
            } else if connectionStatus == .pending {
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Request Pending")
                }
                .font(.headline)
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(16)
            } else if connectionStatus == .accepted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Connected")
                }
                .font(.headline)
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.green.opacity(0.1))
                .cornerRadius(16)
            }
            
            // Coffee Treat Button (works regardless of connection status)
            Button {
                onTreat()
                dismiss()
            } label: {
                HStack {
                    Text("☕")
                    Text("Buy a Coffee")
                }
                .font(.headline)
                .foregroundStyle(Color.coffeeDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.sunRay)
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Safety Actions
    
    var safetyActions: some View {
        HStack(spacing: 24) {
            Button {
                onBlock()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "hand.raised")
                    Text("Block")
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
            
            Button {
                onReport()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.bubble")
                    Text("Report")
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
