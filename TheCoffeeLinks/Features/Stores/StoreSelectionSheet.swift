//
//  StoreSelectionSheet.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct StoreSelectionSheet: View {
    @StateObject private var viewModel: StoresViewModel
    let onSelect: (Store) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: StoresViewModel, onSelect: @escaping (Store) -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSelect = onSelect
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: AppLayout.marginCompact) {
                    HStack(alignment: .top, spacing: AppLayout.spacing) {
                        Text(String(localized: "store_selection_title"))
                            .font(AppTypography.displayMedium)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                                .padding(12)
                                .background {
                                    Circle()
                                        .fill(Color.bgPrimary)
                                }
                                .overlay {
                                    Circle()
                                        .strokeBorder(Color.borderSecondary, lineWidth: 1)
                                }
                        }
                    }
                    .frame(minHeight: AppLayout.touchTarget)

                    Divider()
                        .background(Color.borderSecondary)
                        .padding(.horizontal, -AppLayout.spacing)
                }
                .padding(.horizontal, AppLayout.spacing)
                .padding(.top, AppLayout.spacing)
                .background(Color.bgPrimary)
                
                // Search
                VStack {
                    HStack(spacing: AppLayout.spacingMedium) {
                        Image("magnifyingglass")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textSecondary)
                        
                        TextField("Search stores...", text: $viewModel.searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(AppFont.body)
                            .foregroundStyle(Color.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                    }
                }
                .padding(AppLayout.spacing)
                
                if viewModel.isLoading && viewModel.stores.isEmpty {
                    ReceiptLoadingLog()
                        .padding(AppLayout.spacing)
                } else if viewModel.filteredStores.isEmpty {
                    VStack(spacing: AppLayout.spacing) {
                        Image("mappin.slash")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.textSecondary)
                        Text(String(localized: "stores_empty_search"))
                            .font(AppFont.body)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppLayout.spacing) {
                            ForEach(viewModel.filteredStores) { store in
                                StoreCard(store: store, viewModel: viewModel)
                                    .onTapGesture {
                                        viewModel.selectStore(store)
                                        onSelect(store)
                                        dismiss()
                                    }
                            }
                        }
                        .padding(AppLayout.spacing)
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
