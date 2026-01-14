//
//  StoreSelectionSheet.swift
//  thecoffeelinks-native-swift
//
//  Sheet for selecting a store to check in
//

import SwiftUI

struct StoreSelectionSheet: View {
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var stores: [Store] = []
    @State private var isLoading = true
    @State private var selectedStoreId: String?
    
    private let storeService = StoreService()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(Color.brandAccent)
                    
                    Text("Choose Location")
                        .font(.brandSerif(24))
                        .foregroundStyle(Color.coffeeDark)
                    
                    Text("Select the Coffee Links you're at")
                        .font(.brandSans(14))
                        .foregroundStyle(Color.neutral600)
                }
                .padding(.vertical, 24)
                
                // Store List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if stores.isEmpty && isLoading {
                            ForEach(0..<3, id: \.self) { _ in
                                StoreSkeleton()
                            }
                        } else if stores.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundStyle(Color.neutral400)
                                
                                Text("No stores found")
                                    .font(.brandSans(16))
                                    .foregroundStyle(Color.neutral600)
                                
                                Button("Retry") {
                                    Task { await fetchStores() }
                                }
                                .font(.caption.bold())
                            }
                            .padding(.vertical, 40)
                        } else {
                            ForEach(stores) { store in
                                StoreSelectCard(
                                    store: store,
                                    isSelected: selectedStoreId == store.id,
                                    onSelect: { selectedStoreId = store.id }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Bottom Action
                VStack(spacing: 12) {
                    Button {
                        guard let storeId = selectedStoreId else { return }
                        onSelect(storeId)
                        dismiss()
                    } label: {
                        Text("Check In")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(selectedStoreId != nil ? Color.forestCanopy : Color.neutral300)
                            .cornerRadius(16)
                    }
                    .disabled(selectedStoreId == nil)
                }
                .padding()
                .background(Color.white)
            }
            .background(Color.brandBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .task {
                if stores.isEmpty {
                    await fetchStores()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func fetchStores() async {
        isLoading = true
        do {
            stores = try await storeService.getStores()
        } catch {
            print("Failed to fetch stores: \(error)")
        }
        isLoading = false
    }
}

struct StoreSelectCard: View {
    let store: Store
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Store Icon
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title2)
                    .foregroundStyle(Color.forestCanopy)
                    .frame(width: 48, height: 48)
                    .background(Color.forestCanopy.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.coffeeDark)
                    
                    Text(store.address)
                        .font(.caption)
                        .foregroundStyle(Color.neutral600)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.forestCanopy)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.forestCanopy.opacity(0.1) : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.forestCanopy : Color.neutral200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct StoreSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.neutral200)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.neutral200)
                    .frame(width: 140, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.neutral100)
                    .frame(width: 200, height: 12)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}
