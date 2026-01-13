//
//  VouchersView.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI

struct VouchersView: View {
    @StateObject private var viewModel = VouchersViewModel()
    @State private var selectedTab: Int = 0
    @State private var showingQRCode: Bool = false
    @State private var selectedVoucherCode: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    header
                    
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        tabButton(title: "Available", index: 0)
                        tabButton(title: "Used", index: 1)
                        tabButton(title: "Expired", index: 2)
                    }
                    .padding(4)
                    .background(Color.coffeeRich.opacity(0.05))
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    
                    if viewModel.viewState == .loading && viewModel.vouchers.isEmpty {
                        ProgressView().padding(.top, 40)
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                let filteredVouchers = getFilteredVouchers()
                                
                                if filteredVouchers.isEmpty {
                                    Text("No vouchers in this category")
                                        .font(.brandSans(14))
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 40)
                                } else {
                                    ForEach(filteredVouchers) { voucher in
                                        VoucherCard(voucher: voucher)
                                            .onTapGesture {
                                                if !(voucher.isUsed ?? false) {
                                                    selectedVoucherCode = voucher.code
                                                    showingQRCode = true
                                                }
                                            }
                                    }
                                }
                            }
                            .padding()
                        }
                        .refreshable {
                            await viewModel.fetchVouchers()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingQRCode) {
                if let code = selectedVoucherCode {
                    QRCodeSheet(code: code)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            }
            .task {
                await viewModel.fetchVouchers()
            }
        }
    }
    
    var header: some View {
        HStack {
            Text("Wallet")
                .font(.brandSerif(32))
                .foregroundStyle(Color.brandPrimary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    func tabButton(title: String, index: Int) -> some View {
        Button {
            withAnimation { selectedTab = index }
        } label: {
            Text(title)
                .font(.brandSans(14))
                .fontWeight(.medium)
                .foregroundStyle(selectedTab == index ? Color.white : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedTab == index ? Color.coffeeDark : Color.clear)
                .clipShape(Capsule())
        }
    }
    
    func getFilteredVouchers() -> [Voucher] {
        switch selectedTab {
        case 0: // Available
            return viewModel.vouchers.filter { !($0.isUsed ?? false) } 
        case 1: // Used
            return viewModel.vouchers.filter { $0.isUsed ?? false }
        case 2: // Expired
             return viewModel.vouchers.filter { voucher in
                 if let expires = voucher.expiresAt {
                     return expires < Date() && !(voucher.isUsed ?? false)
                 }
                 return false
             }
        default:
            return []
        }
    }
}

struct VoucherCard: View {
    let voucher: Voucher
    
    var isGold: Bool {
        return (voucher.type ?? "") == "gold" || (voucher.value ?? 0) > 20
    }
    
    var body: some View {
        HStack {
            // Voucher Image or Icon
            ZStack {
                Circle()
                    .fill(isGold ? Color.gold.opacity(0.2) : Color.sage.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                if let imageUrl = voucher.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                        default:
                            Image(systemName: isGold ? "star.fill" : "ticket.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundStyle(isGold ? Color.gold : Color.sage)
                        }
                    }
                } else {
                    Image(systemName: isGold ? "star.fill" : "ticket.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(isGold ? Color.gold : Color.sage)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(voucher.description ?? "Voucher") 
                    .font(.brandSerif(18))
                    .foregroundStyle(Color.coffeeDark)
                
                Text(voucher.code)
                    .font(.brandSans(13))
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer()
            
            if !(voucher.isUsed ?? false) {
                Image("chevron_right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundStyle(.gray)
            }
        }
        .padding(16)
        .background(
            ZStack {
                Color.white
                if isGold {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.gold.opacity(0.5), .white, .gold.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct QRCodeSheet: View {
    let code: String
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Scan to Redeem")
                .font(.brandSerif(24))
                .padding(.top, 32)
            
            Image("qr_code")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundStyle(Color.coffeeDark)
            
            Text(code)
                .font(.brandSans(24).monospaced())
                .fontWeight(.bold)
                .foregroundStyle(Color.coffeeDark)
            
            Text("Show this code to the barista")
                .font(.brandSans(14))
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    VouchersView()
}
