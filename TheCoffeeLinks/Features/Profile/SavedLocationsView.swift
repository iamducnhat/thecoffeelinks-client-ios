//
//  SavedLocationsView.swift
//  thecoffeelinks-client-ios
//
//  Created for Profile Feature
//

import SwiftUI

struct SavedLocationsView: View {
    @Environment(\.dismiss) var dismiss
    
    // Stub data
    @State private var savedLocations: [SavedLocation] = [
        SavedLocation(id: "1", name: "Home", address: "123 Coffee St, New York, NY", icon: "house"),
        SavedLocation(id: "2", name: "Office", address: "456 Work Ave, New York, NY", icon: "briefcase")
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textInk)
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "action_saved_locations"))
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    // Invisible button to balance layout
                    Image(systemName: "chevron.left").opacity(0)
                        
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                    .opacity(0.1)
                
                ScrollView {
                    VStack(spacing: AppLayout.spacing) {
                        ForEach(savedLocations) { location in
                            LocationRow(location: location)
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}

struct SavedLocation: Identifiable {
    let id: String
    let name: String
    let address: String
    let icon: String
}

struct LocationRow: View {
    let location: SavedLocation
    
    var body: some View {
        HStack(spacing: AppLayout.spacing) {
            ZStack {
                Circle()
                    .fill(Color.surfaceCard)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle().stroke(Color.border, lineWidth: 1)
                    )
                
                Image(location.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.textMuted)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(AppFont.body)
                    .foregroundStyle(Color.textInk)
                
                Text(location.address)
                    .font(AppFont.uiCaption)
                    .foregroundStyle(Color.textMuted)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image("pencil")
                .font(.system(size: 16))
                .foregroundStyle(Color.textMuted)
        }
        .padding(AppLayout.spacing)
        .background(Color.backgroundPaper)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
    }
}
