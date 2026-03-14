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
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (aligned with product detail pattern)
                VStack(spacing: AppLayout.marginCompact) {
                    HStack(alignment: .center, spacing: AppLayout.spacing) {
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
                                .background { Circle().fill(Color.bgPrimary) }
                                .overlay { Circle().strokeBorder(Color.borderSecondary, lineWidth: 1) }
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
                
                // Embedded StoresView logic/content
                ScrollView {
                    LazyVStack(spacing: AppLayout.spacing) {
                        if storeViewModel.stores.isEmpty {
                            Text("Loading stores...")
                                .font(AppFont.body)
                                .foregroundStyle(Color.textSecondary)
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
                    .padding(AppLayout.spacing)
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
        HStack(spacing: AppLayout.spacing) {
            // Simplified content compared to full StoreCard
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(AppFont.headline)
                    .foregroundStyle(Color.textPrimary)
                
                Text(store.address)
                    .font(AppFont.uiCaption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(store.isCurrentlyOpen ? Color.stateSuccess : Color.stateError)
                        .frame(width: 6, height: 6)
                    Text(store.isCurrentlyOpen ? "Open" : "Closed")
                        .font(AppFont.uiCaption)
                        .foregroundStyle(store.isCurrentlyOpen ? Color.stateSuccess : Color.stateError)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image("circle_check")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.accentPrimary)
            }
        }
        .padding(AppLayout.spacing)
        .background(Color.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .strokeBorder(isSelected ? Color.accentPrimary : Color.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }
}
