//
//  VouchersView.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Tab-based voucher interface with image support
//

import SwiftUI
import Combine

enum VoucherTab: String, CaseIterable {
    case available = "Available"
    case used = "Used"
}

struct VouchersView: View {
    @StateObject private var viewModel: VouchersViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: VoucherTab = .available
    let onSelect: (Voucher) -> Void
    
    init(onSelect: @escaping (Voucher) -> Void, voucherRepository: VoucherRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: VouchersViewModel(voucherRepository: voucherRepository))
        self.onSelect = onSelect
    }
    
    var filteredVouchers: [Voucher] {
        switch selectedTab {
        case .available:
            return viewModel.vouchers.filter { $0.isValid }
        case .used:
            // For now, show expired/inactive vouchers as "used"
            // TODO: Track actual user usage when backend supports it
            return viewModel.vouchers.filter { !$0.isValid }
        }
    }
    
    var body: some View {
        ZStack {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: AppLayout.spacing) {
                    HStack {
                        Text("Vouchers")
                            .font(AppFont.displayTitle)
                            .foregroundStyle(Color.textInk)
                        
                        Spacer()
                        
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(AppFont.navIcon)
                                .foregroundStyle(Color.textInk)
                        }
                    }
                    
                    Color.secondary.frame(height: 1)
                    
                    // Tab Picker
                    HStack(spacing: 0) {
                        ForEach(VoucherTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = tab
                                }
                            } label: {
                                Text(tab.rawValue)
                                    .font(AppFont.monoBody)
                                    .foregroundStyle(selectedTab == tab ? Color.backgroundPaper : Color.textInk)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppLayout.spacingCompact)
                                    .background(selectedTab == tab ? Color.primaryEspresso : Color.backgroundPaper)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.border, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(Color.border, lineWidth: 1)
                    )
                }
                .padding(AppLayout.spacing)
                
                ScrollView {
                    LazyVStack(spacing: AppLayout.spacing) {
                        if viewModel.isLoading {
                            ReceiptLoadingLog()
                        } else if filteredVouchers.isEmpty {
                            VStack(spacing: AppLayout.spacing) {
                                Text("No vouchers")
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textInk)
                                
                                Text(selectedTab == .available 
                                     ? "No vouchers available at this time." 
                                     : "You haven't used any vouchers yet.")
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textMuted)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                            )
                        } else {
                            ForEach(filteredVouchers) { voucher in
                                VoucherCard(voucher: voucher, showApplyButton: selectedTab == .available) {
                                    onSelect(voucher)
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppLayout.spacing)
                    .padding(.bottom, AppLayout.spacingXL)
                }
            }
        }
        .task { await viewModel.load() }
    }
}

@MainActor
final class VouchersViewModel: ObservableObject {
    @Published var vouchers: [Voucher] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let voucherRepository: VoucherRepositoryProtocol
    
    init(voucherRepository: VoucherRepositoryProtocol) {
        self.voucherRepository = voucherRepository
    }
    
    func load() async {
        isLoading = true
        error = nil
        do {
            vouchers = try await voucherRepository.getVouchers()
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
