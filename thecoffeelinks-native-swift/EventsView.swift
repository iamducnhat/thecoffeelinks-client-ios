//
//  EventsView.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI

struct EventsView: View {
    @StateObject private var viewModel = EventsViewModel()
    
    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()
            
            switch viewModel.viewState {
            case .loading:
                ProgressView()
            case .error(let message):
                VStack {
                    Text("Error")
                    Text(message).font(.caption).foregroundStyle(.red)
                    Button("Retry") { Task { await viewModel.fetchEvents() } }
                }
            case .empty:
                emptyState
            case .idle, .loaded:
                List {
                    Section {
                        if viewModel.events.isEmpty {
                            emptyState
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.events) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventRow(event: event)
                                }
                                .listRowBackground(Color.white)
                            }
                        }
                    } header: {
                        Text("Upcoming Events")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Section {
                        Button {
                            // Archive logic
                        } label: {
                            Text("View Past Events")
                                .font(.brandSans(14))
                                .foregroundStyle(Color.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.fetchEvents()
                }
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchEvents()
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Image("calendar")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundStyle(Color.sage)
            
            Text("Quiet week?")
                .font(.brandSerif(24))
                .foregroundStyle(Color.coffeeDark)
            
            Text("Host your own meetup or check back later for community updates.")
                .font(.brandSans(16))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.secondary)
                .padding(.horizontal)
            
            LiquidGlassPrimaryButton("Host an Event") {
                // Host event action
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    

}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 16) {
            // Event Image Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.coffeeRich.opacity(0.05))
                    .frame(width: 60, height: 60)
                
                if let imageUrl = event.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure(_):
                            Image("calendar")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color.coffeeRich)
                        case .empty:
                            Image("calendar")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color.coffeeRich)
                        @unknown default:
                            Image("calendar")
                                .resizable()
                                .renderingMode(.template) 
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color.coffeeRich)
                        }
                    }
                } else {
                    Image("calendar")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.coffeeRich)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.brandSans(16))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.coffeeDark)
                
                if let type = event.type {
                    Text(type.uppercased())
                        .font(.brandSans(10))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.caramel)
                }
                
                if let date = event.date {
                    Text(date.formatted(.dateTime.month().day().year()))
                        .font(.brandSans(12))
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EventsView()
}
