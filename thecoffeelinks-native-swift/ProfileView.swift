//
//  ProfileView.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isNetworkingVisible: Bool = true
    @EnvironmentObject var appState: AppState // Keep for now if needed for other global state
    
    var body: some View {
        NavigationStack {
            List {
                switch viewModel.viewState {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    
                case .error(let message):
                    VStack {
                        Text("Error loading profile")
                            .font(.headline)
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Button("Retry") {
                            Task { await viewModel.fetchProfile() }
                        }
                    }
                    .listRowBackground(Color.clear)
                    
                case .loaded, .idle:
                    // MARK: - Identity Section
                    Section {
                        VStack(alignment: .center, spacing: 12) {
                            // Avatar
                            if let avatarUrl = viewModel.user?.avatarUrl, let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                         .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.coffeeRich
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            } else {
                                Circle()
                                    .fill(Color.coffeeRich)
                                    .frame(width: 80, height: 80)
                                    .overlay {
                                        Text(String(viewModel.user?.fullName?.prefix(1) ?? "U"))
                                            .font(.brandSerif(32))
                                            .foregroundStyle(Color.ivory)
                                    }
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            }
                            
                            Text(viewModel.user?.fullName ?? "User")
                                .font(.brandSerif(24))
                                .foregroundStyle(Color.coffeeDark)
                            
                            Text(viewModel.user?.jobTitle ?? "Member")
                                .font(.brandSans(14))
                                .foregroundStyle(Color.secondary)
                            
                            if let bio = viewModel.user?.bio {
                                Text(bio)
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // Trust Badges
                            HStack(spacing: 8) {
                                BadgeView(text: "Verified Member", icon: "badge_check", color: .sage)
                                BadgeView(text: "Top Connector", icon: "network", color: .gold)
                            }
                            .padding(.top, 4)
                            
                            // Edit / Public View Toggle
                            Button {
                                // Toggle edit mode
                            } label: {
                                Text("Edit Public Profile")
                                    .font(.brandSans(12))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.caramel)
                                    .padding(.vertical, 8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .padding(.bottom, 20)
                    }
                    
                    // MARK: - Networking Control
                    Section {
                        Toggle(isOn: $isNetworkingVisible) {
                            HStack {
                                Image(isNetworkingVisible ? "eye" : "eye_off")
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(isNetworkingVisible ? Color.sage : Color.secondary)
                                
                                VStack(alignment: .leading) {
                                    Text("Networking Visibility")
                                        .font(.brandSans(16))
                                        .foregroundStyle(Color.coffeeDark)
                                    
                                    Text(isNetworkingVisible ? "Visible to nearby members" : "Hidden from everyone")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                        .tint(Color.sage)
                    } header: {
                        Text("Privacy & Control")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.secondary)
                    }
                    .listRowBackground(Color.white)
                    
                    // MARK: - Account
                    Section {
                        NavigationLink { Text("Orders History") } label: {
                            Label {
                                Text("Order History")
                                    .font(.brandSans(16))
                            } icon: {
                                Image("clock")
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(Color.coffeeDark)
                            }
                        }
                        
                        NavigationLink { Text("Settings") } label: {
                            Label {
                                Text("Settings")
                                    .font(.brandSans(16))
                            } icon: {
                                Image("settings")
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(Color.coffeeDark)
                            }
                        }
                        
                        Button(role: .destructive) {
                            Task {
                                await viewModel.signOut()
                            }
                        } label: {
                             Label {
                                 Text("Sign Out")
                             } icon: {
                                 Image("log_out")
                                     .resizable()
                                     .renderingMode(.template)
                                     .aspectRatio(contentMode: .fit)
                                     .frame(width: 20, height: 20)
                             }
                        }
                    } header: {
                        Text("Account")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.secondary)
                    }
                    .listRowBackground(Color.white)
                    
                default:
                    EmptyView()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.brandBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.fetchProfile()
            }
        }
    }
    

}

struct BadgeView: View {
    let text: String
    let icon: String // Asset symbol name
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(icon)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
            Text(text)
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}


#Preview {
    ProfileView()
        .environmentObject(AppState())
}
