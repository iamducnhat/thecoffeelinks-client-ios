import SwiftUI

struct FavoritesManagementView: View {
    @StateObject private var vm = FavoritesViewModel(favoritesRepository: DependencyContainer.shared.favoritesRepository)
    
    var body: some View {
        List {
            ForEach(vm.favorites) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.product.name).font(.headline)
                        if let notes = item.notes {
                            Text("Note: \(notes)")
                                .font(.caption).italic().foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    Button(action: { /* Quick Order Logic */ }) {
                        Image(systemName: "cart.badge.plus")
                            .foregroundColor(Editorial.Colors.primaryEspresso)
                    }
                }
            }
            .onDelete { indexSet in
                if let index = indexSet.first {
                    let item = vm.favorites[index]
                    Task { await vm.removeFavorite(id: item.id) }
                }
            }
        }
        .navigationTitle("My Favorites")
        .toolbar { EditButton() }
        .onAppear { Task { await vm.load() } }
    }
}

// Simple Home Section Component
struct FavoritesSection: View {
    @StateObject var vm = FavoritesViewModel(favoritesRepository: DependencyContainer.shared.favoritesRepository)
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Favorites")
                .font(Editorial.uiBody())
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(vm.favorites) { item in
                        FavoriteCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear { Task { await vm.load() } }
    }
}

struct FavoriteCard: View {
    let item: FavoriteItem
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.product.name).bold()
            Text(item.notes ?? "No notes").font(.caption).foregroundColor(.gray)
            Spacer()
            HStack {
                Text("$\(String(format: "%.2f", item.product.price))")
                Spacer()
                Image(systemName: "heart.fill").foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 140, height: 140)
        .background(Editorial.Colors.secondaryBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
