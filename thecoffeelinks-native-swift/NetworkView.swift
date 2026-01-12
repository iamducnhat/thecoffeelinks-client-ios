import SwiftUI

struct NetworkView: View {
    @StateObject private var viewModel = NetworkViewModel()
    @EnvironmentObject var appState: AppState // For user context if needed
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    header
                    
                    // Main Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Check-in Status / Action
                            if !viewModel.isCheckedIn {
                                Button {
                                    Task { await viewModel.checkIn() }
                                } label: {
                                    HStack {
                                        Image("map_pin")
                                        Text("Check In to Networking Lounge")
                                            .fontWeight(.bold)
                                    }
                                    .font(.brandSans(16))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.coffeeRich)
                                    .cornerRadius(16)
                                    .shadow(color: Color.coffeeRich.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                            } else {
                                HStack {
                                    Circle()
                                        .fill(Color.sage)
                                        .frame(width: 8, height: 8)
                                    Text("You are checked in")
                                        .font(.brandSans(14))
                                        .foregroundStyle(Color.sage)
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.05), radius: 5)
                            }
                            
                            // List of People
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Here Now")
                                    .font(.brandSerif(20))
                                    .foregroundStyle(Color.coffeeDark)
                                
                                if viewModel.viewState == .loading && viewModel.checkedInUsers.isEmpty {
                                    skeletonView
                                } else if viewModel.checkedInUsers.isEmpty {
                                    VStack(spacing: 8) {
                                        Image("network")
                                            .font(.largeTitle)
                                            .foregroundStyle(Color.secondary)
                                        Text("It's quiet... too quiet.")
                                            .font(.brandSans(14))
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 40)
                                } else {
                                    ForEach(viewModel.checkedInUsers, id: \.id) { checkIn in
                                        NetworkUserCard(checkIn: checkIn)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.fetchCheckIns()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .task {
                await viewModel.fetchCheckIns()
            }
        }
    }
    
    var header: some View {
        HStack {
            Text("Network")
                .font(.brandSerif(32))
                .foregroundStyle(Color.brandPrimary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    var skeletonView: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                
                // Status Placeholder
                HStack {
                    Circle()
                        .fill(Color.sage)
                        .frame(width: 8, height: 8)
                    Text("Checking status...")
                        .font(.brandSans(14))
                        .foregroundStyle(Color.sage)
                }
                .padding()
                .background(Color.white)
                .clipShape(Capsule())
                
                // List of People
                VStack(alignment: .leading, spacing: 16) {
                    Text("Here Now")
                        .font(.brandSerif(20))
                        .foregroundStyle(Color.coffeeDark)
                    
                    ForEach(0..<4) { _ in
                        NetworkUserCard(checkIn: .placeholder)
                    }
                }
            }
            .padding()
        }
        .redacted(reason: .placeholder)
        .disabled(true)
    }
}

struct NetworkUserCard: View {
    let checkIn: CheckIn
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            if let user = checkIn.user, let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.coffeeRich.opacity(0.2)
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.coffeeRich)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Text(String(checkIn.user?.fullName?.prefix(1) ?? "U"))
                            .font(.brandSerif(24))
                            .foregroundStyle(.white)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(checkIn.user?.fullName ?? "Guest")
                    .font(.brandSerif(18))
                    .foregroundStyle(Color.coffeeDark)
                
                if let job = checkIn.user?.jobTitle {
                    Text(job)
                        .font(.brandSans(14))
                        .foregroundStyle(Color.secondary)
                }
                
                if let industry = checkIn.user?.industry {
                    Text(industry)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.coffeeRich.opacity(0.1))
                        .foregroundStyle(Color.coffeeRich)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Button {
                // Connect Acton
            } label: {
                Image("network")
                    .foregroundStyle(Color.brandAccent)
                    .padding(10)
                    .background(Color.brandAccent.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
