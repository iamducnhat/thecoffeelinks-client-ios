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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text(String(localized: "common_close"))
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "store_selection_title"))
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Text(String(localized: "common_close")).font(AppFont.body).hidden()
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                // Embedded StoresView logic/content
                // Since StoresView is complex, let's use a simplified list here interacting with StoreViewModel
                ScrollView {
                    LazyVStack(spacing: AppLayout.spacing) {
                        if storeViewModel.stores.isEmpty {
                            Text("Loading stores...")
                                .font(AppFont.body)
                                .foregroundStyle(Color.textMuted)
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
                    .foregroundStyle(Color.textInk)
                
                Text(store.address)
                    .font(AppFont.uiCaption)
                    .foregroundStyle(Color.textMuted)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(store.isCurrentlyOpen ? Color.semanticSuccess : Color.semanticError)
                        .frame(width: 6, height: 6)
                    Text(store.isCurrentlyOpen ? "Open" : "Closed")
                        .font(AppFont.uiCaption)
                        .foregroundStyle(store.isCurrentlyOpen ? Color.semanticSuccess : Color.semanticError)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.primaryEspresso)
            }
        }
        .padding(AppLayout.spacing)
        .background(isSelected ? Color.surfaceCard : Color.backgroundPaper)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(isSelected ? Color.primaryEspresso : Color.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
    }
}
