//
//  StorePickerSheet.swift
//  thecoffeelinks-client-ios
//
//  Sheet for selecting a store for pickup
//

import SwiftUI

struct StorePickerSheet: View {
    @EnvironmentObject var storeViewModel: StoreViewModel
    @Environment(\.dismiss) private var dismiss
    
    // We can reuse the StoresView content but wrapped in a sheet layout
    // Or we can build a simplified list since StoresView has its own specific layout (tabs, search etc)
    // Reusing StoresView might be best for consistency if it fits well.
    // However, StoresView assumes full screen. Let's create a lightweight wrapper.
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (aligned with product detail pattern)
                VStack(spacing: BaseViewLayout.marginCompact) {
                    HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                        Text(String(localized: "store_selection_title"))
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

                    Divider()
                        .background(BaseViewColor.borderSecondary)
                        .padding(.horizontal, -BaseViewLayout.spacing)
                }
                .padding(.horizontal, BaseViewLayout.spacing)
                .padding(.top, BaseViewLayout.spacing)
                .background(BaseViewColor.background)
                
                // Embedded StoresView logic/content
                ScrollView {
                    LazyVStack(spacing: BaseViewLayout.spacing) {
                        if storeViewModel.stores.isEmpty {
                            Text("Loading stores...")
                                .font(BaseViewFont.body)
                                .foregroundStyle(BaseViewColor.textSecondary)
                                .padding(.top, 40)
                        } else {
                            ForEach(storeViewModel.stores) { store in
                                StoreCardSimple(
                                    store: store,
                                    isSelected: storeViewModel.selectedStore?.id == store.id
                                )
                                .onTapGesture {
                                    storeViewModel.selectStore(store)
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(BaseViewLayout.spacing)
                }
            }
        }
        .onAppear {
            if storeViewModel.stores.isEmpty {
                storeViewModel.loadStores()
            }
        }
    }
}

// MARK: - Simple Store Card
struct StoreCardSimple: View {
    let store: Store
    let isSelected: Bool
    
    var body: some View {
        AppStoreCard(
            title: store.name,
            address: store.address,
            statusText: store.isCurrentlyOpen ? "Open" : "Closed",
            isSelected: isSelected,
            variant: .simple
        )
    }
}
