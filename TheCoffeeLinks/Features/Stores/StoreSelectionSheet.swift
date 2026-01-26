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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text(String(localized: "common_cancel"))
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "store_selection_title"))
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 50)
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                // Search
                VStack {
                    HStack(spacing: AppLayout.spacingMedium) {
                        Image("magnifyingglass")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                        
                        TextField("Search stores...", text: $viewModel.searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(AppFont.body)
                            .foregroundStyle(Color.textInk)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
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
                            .foregroundStyle(Color.textMuted)
                        Text(String(localized: "stores_empty_search"))
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
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
