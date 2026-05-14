//
//  VouchersView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
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
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: BaseViewLayout.lg) {
                    HStack(alignment: .center, spacing: BaseViewLayout.md) {
                        Text(String(localized: "vouchers_title"))
                            .font(BaseViewFont.displayMedium)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(BaseViewColor.textPrimary)
                                .padding(12)
                                .background { Circle().fill(BaseViewColor.background) }
                                .overlay { Circle().strokeBorder(BaseViewColor.borderSecondary, lineWidth: 1) }
                        }
                    }
                    .frame(minHeight: BaseViewLayout.touchTarget)
                    .padding(.horizontal, BaseViewLayout.screenPadding)
                    
                    Divider()
                        .background(BaseViewColor.borderSecondary)
                        .padding(.horizontal, -BaseViewLayout.screenPadding)
                    
                    // Tab Picker - aligned with Stores segmented style
                    AppSegmentedPicker(
                        selection: $selectedTab,
                        options: VoucherTab.allCases.map { ($0, $0.rawValue) }
                    )
                    .padding(.horizontal, BaseViewLayout.screenPadding)
                }
                .padding(.top, BaseViewLayout.spacing)
                .background(BaseViewColor.background)
                
                ScrollView {
                    LazyVStack(spacing: BaseViewLayout.spacing) {
                        if viewModel.isLoading {
                            ReceiptLoadingLog()
                        } else if filteredVouchers.isEmpty {
                            VStack(spacing: BaseViewLayout.spacing) {
                                Text(String(localized: "vouchers_empty"))
                                    .font(BaseViewFont.sectionHeader)
                                    .foregroundStyle(BaseViewColor.textPrimary)
                                
                                Text(selectedTab == .available 
                                     ? "No vouchers available at this time." 
                                     : "You haven't used any vouchers yet.")
                                    .font(BaseViewFont.body)
                                    .foregroundStyle(BaseViewColor.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                            .overlay(
                                Capsule()
                                    .strokeBorder(BaseViewColor.border, style: StrokeStyle(lineWidth: 1, dash: BaseViewLayout.dashedPattern))
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
                    .padding(.horizontal, BaseViewLayout.spacing)
                    .padding(.bottom, BaseViewLayout.spacingXL)
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
