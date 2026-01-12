//
//  EventsView.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI

struct EventsView: View {
    @StateObject private var viewModel = EventsViewModel()
    @State private var selectedEventId: String? // Changed to String to match Model
    
    var body: some View {
        NavigationStack {
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
                    ScrollView {
                         VStack(spacing: 24) {
                             header
                             
                             if viewModel.events.isEmpty {
                                 emptyState
                             } else {
                                 ForEach(viewModel.events) { event in
                                     EventCard(event: event)
                                         .onTapGesture {
                                             withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                 selectedEventId = event.id
                                             }
                                         }
                                 }
                             }
                             
                             Button {
                                 // Archive logic
                             } label: {
                                 Text("View Past Events")
                                     .font(.brandSans(14))
                                     .foregroundStyle(Color.secondary)
                                     .padding(.top, 16)
                             }
                         }
                         .padding()
                     }
                     .refreshable {
                         await viewModel.fetchEvents()
                     }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .task {
                await viewModel.fetchEvents()
            }
        }
    }
    
    var header: some View {
        HStack {
            Text("Events")
                .font(.brandSerif(32))
                .foregroundStyle(Color.brandPrimary)
            Spacer()
        }
        .padding(.bottom, 8)
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
            
            Button {
                // Host event action
            } label: {
                Text("Host an Event")
                    .font(.brandSans(16))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.coffeeDark)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .padding(.top, 40)
    }
}

struct EventCard: View {
    let event: Event // Using the Model 'Event'
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Area
            Rectangle()
                .fill(Color.coffeeRich.opacity(0.05))
                .frame(height: 180)
                .overlay {
                    // Use system image for 'icon' or AsyncImage if 'bg' is actually an image URL?
                    // Model has 'icon' and 'bg'. In Typescript 'bg' was class name.
                    // Here let's just use SF symbol from 'icon' field if applicable, or generic.
                    Image("calendar") // Lucide icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundStyle(Color.coffeeRich)
                }
            
            // Content Area
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text((event.type ?? "Event").uppercased())
                        .font(.brandSans(12))
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.coffeeDark)
                        .foregroundStyle(Color.white)
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                Text(event.title)
                    .font(.brandSerif(22))
                    .foregroundStyle(Color.coffeeDark)
                
                Text(event.description ?? "")
                    .font(.brandSans(14))
                    .foregroundStyle(Color.secondary)
            }
            .padding(20)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    EventsView()
}
