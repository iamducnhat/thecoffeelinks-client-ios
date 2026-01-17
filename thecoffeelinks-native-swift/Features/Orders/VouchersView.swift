//
//  VouchersView.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import Combine

struct VouchersView: View {
    @StateObject private var viewModel: VouchersViewModel
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Voucher) -> Void
    
    init(onSelect: @escaping (Voucher) -> Void, voucherRepository: VoucherRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: VouchersViewModel(voucherRepository: voucherRepository))
        self.onSelect = onSelect
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
                }
                .padding(AppLayout.spacing)
                
                ScrollView {
                    LazyVStack(spacing: AppLayout.spacing) {
                        if viewModel.isLoading {
                            ReceiptLoadingLog()
                        } else if viewModel.vouchers.isEmpty {
                            VStack(spacing: AppLayout.spacing) {
                                Text("No vouchers")
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textInk)
                                
                                Text("No vouchers available at this time.")
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                            )
                        } else {
                            ForEach(viewModel.vouchers) { voucher in
                                VoucherCard(voucher: voucher) {
                                    onSelect(voucher)
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppLayout.spacing)
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
