import SwiftUI

/// View for selecting or managing saved delivery addresses
struct SavedAddressesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var addresses: [Address] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let onSelectAddress: (String) -> Void
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading addresses...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if addresses.isEmpty {
                    emptyStateView
                } else {
                    addressesList
                }
            }
            .navigationTitle("Saved Addresses")
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
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
        .task {
            await loadAddresses()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Saved Addresses")
                .font(.headline)
            
            Text("Addresses will be saved automatically when you place a delivery order")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var addressesList: some View {
        List {
            ForEach(addresses) { address in
                Button(action: {
                    onSelectAddress(address.address)
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(address.address)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            if let createdAt = address.createdAt {
                                Text("Saved \(createdAt, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await deleteAddress(address)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Actions
    
    private func loadAddresses() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            addresses = try await AddressService.shared.fetchAddresses()
        } catch {
            errorMessage = "Failed to load addresses: \(error.localizedDescription)"
        }
    }
    
    private func deleteAddress(_ address: Address) async {
        do {
            try await AddressService.shared.deleteAddress(id: address.id)
            // Remove from local list
            addresses.removeAll { $0.id == address.id }
        } catch {
            errorMessage = "Failed to delete address: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SavedAddressesView { address in
        print("Selected: \(address)")
    }
}
