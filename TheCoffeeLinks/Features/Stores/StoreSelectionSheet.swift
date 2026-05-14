//
//  StoreSelectionSheet.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
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
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: BaseViewLayout.spacing) {
                        Text(String(localized: "store_selection_title"))
                            .font(BaseViewFont.sectionTitle)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(BaseViewColor.textPrimary)
                                .frame(width: BaseViewLayout.touchTarget, height: BaseViewLayout.touchTarget)
                        }
                    }
                    .frame(minHeight: BaseViewLayout.touchTarget)
                    .padding(.horizontal, BaseViewLayout.screenInset)
                    .padding(.top, BaseViewLayout.screenTopInset)
                    .padding(.bottom, BaseViewLayout.screenInset)

                    Rectangle()
                        .fill(BaseViewColor.border)
                        .frame(height: BaseViewLayout.cardBorderWidth)
                }
                .background(BaseViewColor.background)
                
                VStack {
                    HStack(spacing: BaseViewLayout.spacingMedium) {
                        Image("magnifyingglass")
                            .font(BaseViewFont.body)
                            .foregroundStyle(BaseViewColor.textSecondary)
                        
                        TextField("Search stores...", text: $viewModel.searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(BaseViewFont.body)
                            .foregroundStyle(BaseViewColor.textPrimary)
                    }
                    .padding(.horizontal, BaseViewLayout.badgeInset)
                    .frame(height: BaseViewLayout.rowHeight)
                    .background(BaseViewColor.textPrimary.opacity(0.08))
                }
                .padding(.horizontal, BaseViewLayout.screenInset)
                .padding(.top, BaseViewLayout.sectionGap)
                .padding(.bottom, BaseViewLayout.sectionGap)
                
                if viewModel.isLoading && viewModel.stores.isEmpty {
                    ReceiptLoadingLog()
                        .padding(.horizontal, BaseViewLayout.screenInset)
                } else if viewModel.filteredStores.isEmpty {
                    VStack(spacing: BaseViewLayout.spacing) {
                        Image("mappin.slash")
                            .font(.system(size: 32))
                            .foregroundStyle(BaseViewColor.textSecondary)
                        Text(String(localized: "stores_empty_search"))
                            .font(BaseViewFont.body)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    }
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: BaseViewLayout.cardGap) {
                            ForEach(viewModel.filteredStores) { store in
                                StoreCard(store: store, viewModel: viewModel)
                                    .onTapGesture {
                                        viewModel.selectStore(store)
                                        onSelect(store)
                                        dismiss()
                                    }
                            }
                        }
                        .padding(.horizontal, BaseViewLayout.screenInset)
                        .padding(.bottom, BaseViewLayout.sectionGap)
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
