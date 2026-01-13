import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            // MARK: - Hero Section
            Section {
                VStack(alignment: .center, spacing: 16) {
                    // Image / Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.coffeeRich.opacity(0.05))
                            .frame(width: 120, height: 120)
                        
                        if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                     .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        } else {
                            Image("calendar")
                                .resizable()
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
                        
                        if let host = event.hostName {
                            Text("Hosted by \(host)")
                                .font(.brandSans(14))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button {
                            // Register logic
                        } label: {
                            Text("Register Now")
                                .font(.brandSans(16))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.coffeeDark)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            // Share logic
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.coffeeDark)
                                .frame(width: 48, height: 48)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.neutral200, lineWidth: 1)
                                }
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
                
                if let location = event.location {
                    DetailRow(icon: "map_pin", title: "Location", value: location)
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
                        Text("Community Manager")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
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

#Preview {
    NavigationStack {
        EventDetailView(event: .placeholder)
    }
}
