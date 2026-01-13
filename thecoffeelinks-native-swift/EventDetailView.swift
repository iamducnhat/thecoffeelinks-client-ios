import SwiftUI

struct EventDetailView: View {
    var event: Event
    @Environment(\.dismiss) private var dismiss
    @State private var storeName: String?
    
    var body: some View {
        List {
            // MARK: - Hero Section
            Section {
                VStack(alignment: .center, spacing: 16) {
                    // Event Hero Image
                    ZStack {                    RoundedRectangle(cornerRadius: 24)
                            .fill(Color.coffeeRich.opacity(0.05))
                            .frame(width: 120, height: 120)
                        
                        if let imageUrl = event.imageURL, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                case .failure(_):
                                    Image("calendar")
                                        .resizable()
                                        .renderingMode(.template) 
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .foregroundStyle(Color.coffeeRich)
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    Image("calendar")
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .foregroundStyle(Color.coffeeRich)
                                }
                            }
                        } else {
                            Image("calendar")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .foregroundStyle(Color.coffeeRich)
                        }
                    }
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 8) {
                        if let type = event.type {
                            Text(type.uppercased())
                                .font(.brandSans(12))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.caramel)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.caramel.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        Text(event.title)
                            .font(.brandSerif(28))
                            .foregroundStyle(Color.coffeeDark)
                            .multilineTextAlignment(.center)
                        
//                        if let host = event.hostName {
//                            Text("Hosted by \(host)")
//                                .font(.brandSans(14))
//                                .foregroundStyle(Color.secondary)
//                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        LiquidGlassPrimaryButton("Register Now") {
                            // Register logic
                        }
                        
                        LiquidGlassSecondaryButton("Share", icon: "chevron_right") {
                            // Share logic
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.bottom, 32)
            }
            
            // MARK: - Details Section
            Section {
                if let date = event.date {
                    DetailRow(icon: "clock", title: "Date & Time", value: date.formatted(.dateTime.weekday().month().day().hour().minute()))
                }
                
                if let storeName = storeName {
                    DetailRow(icon: "map_pin", title: "Location", value: storeName)
                } else if event.storeId != nil {
                    DetailRow(icon: "map_pin", title: "Location", value: "Loading...")
                }
            } header: {
                Text("When & Where")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.secondary)
            }
            .listRowBackground(Color.white)
            
            // MARK: - About Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(event.description ?? "No description available for this event.")
                        .font(.brandSans(16))
                        .foregroundStyle(Color.coffeeRich)
                        .lineSpacing(4)
                }
                .padding(.vertical, 8)
            } header: {
                Text("About the Event")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.secondary)
            }
            .listRowBackground(Color.white)
            
            // MARK: - Organizer Section
            Section {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.coffeeRich.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image("user")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color.coffeeDark)
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.hostName ?? "The Coffee Links")
                            .font(.brandSans(16))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.coffeeDark)
                        Text("Organizer")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    
                    Image("chevron_right")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .foregroundStyle(Color.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Organizer")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.secondary)
            }
            .listRowBackground(Color.white)
        }
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                if let store = try? await event.fetchStore() {
                    storeName = store.name
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.caramel)
                .frame(width: 32, height: 32)
                .background(Color.caramel.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Text(value)
                    .font(.brandSans(14))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.coffeeDark)
            }
        }
        .padding(.vertical, 4)
    }
}

//#Preview {
//    NavigationStack {
//        EventDetailView(event: .placeholder)
//    }
//}
