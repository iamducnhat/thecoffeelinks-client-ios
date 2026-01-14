//
//  CoffeeTreatSheet.swift
//  thecoffeelinks-native-swift
//
//  Sheet for sending a coffee treat to another user
//

import SwiftUI

struct CoffeeTreatSheet: View {
    let recipientName: String
    let recipientId: String
    let onSend: (String, String, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var menuRepo = MenuRepository.shared
    
    @State private var selectedProduct: Product?
    @State private var message = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("☕")
                        .font(.system(size: 48))
                    
                    Text("Buy \(recipientName) a coffee")
                        .font(.brandSerif(24))
                        .foregroundStyle(Color.coffeeDark)
                    
                    Text("Choose a drink and add a personal note")
                        .font(.brandSans(14))
                        .foregroundStyle(Color.neutral600)
                }
                .padding(.vertical, 24)
                
                // Product Selection
                ScrollView {
                    VStack(spacing: 16) {
                        // Quick picks - show popular/affordable items
                        if let products = menuRepo.menu?.products {
                            let treatProducts = products.filter { $0.isPopular == true }.prefix(6)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(Array(treatProducts), id: \.id) { product in
                                    TreatProductCard(
                                        product: product,
                                        isSelected: selectedProduct?.id == product.id,
                                        onSelect: { selectedProduct = product }
                                    )
                                }
                            }
                        } else if menuRepo.isLoading {
                            ForEach(0..<4, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.neutral200)
                                    .frame(height: 100)
                            }
                        }
                        
                        // Message
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add a note")
                                .font(.caption.bold())
                                .foregroundStyle(Color.neutral500)
                            
                            TextField("Say something nice...", text: $message, axis: .vertical)
                                .lineLimit(2...4)
                                .padding()
                                .background(Color.neutral100)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
                
                // Bottom Action
                VStack(spacing: 12) {
                    if let product = selectedProduct {
                        HStack {
                            Text(product.name)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            if let price = product.availableSizes.first?.price {
                                Text(price.toVND())
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color.brandAccent)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button {
                        guard let product = selectedProduct else { return }
                        onSend(product.id, product.name, message.isEmpty ? nil : message)
                        dismiss()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Coffee Treat")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedProduct != nil ? Color.forestCanopy : Color.neutral300)
                        .cornerRadius(16)
                    }
                    .disabled(selectedProduct == nil || isLoading)
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
                if menuRepo.menu == nil {
                    await menuRepo.fetchMenu()
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct TreatProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Image
                if let imageUrl = product.displayImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.neutral200
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.coffeeRich)
                        .frame(width: 60, height: 60)
                        .overlay {
                            Text("☕")
                                .font(.title2)
                        }
                }
                
                Text(product.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.coffeeDark)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if let price = product.availableSizes.first?.price {
                    Text(price.toVND())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.brandAccent)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.forestCanopy.opacity(0.1) : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.forestCanopy : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
