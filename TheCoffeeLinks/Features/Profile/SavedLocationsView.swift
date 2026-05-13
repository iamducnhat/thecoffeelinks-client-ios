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
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ProfileNavigationHeader(title: String(localized: "action_saved_locations")) {
                    dismiss()
                }
                
                ScrollView {
                    VStack(spacing: BaseViewLayout.cardGap) {
                        ForEach(savedLocations) { location in
                            LocationRow(location: location)
                        }
                    }
                    .padding(.horizontal, BaseViewLayout.screenInset)
                    .padding(.top, BaseViewLayout.sectionGap)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
        HStack(spacing: BaseViewLayout.badgeInset) {
            ZStack {
                Rectangle()
                    .fill(BaseViewColor.elevatedSurface)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Rectangle().stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
                    )
                
                Image(location.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(BaseViewColor.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(BaseViewFont.body)
                    .foregroundStyle(BaseViewColor.textPrimary)
                
                Text(location.address)
                    .font(BaseViewFont.label)
                    .foregroundStyle(BaseViewColor.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image("pencil")
                .font(.system(size: 16))
                .foregroundStyle(BaseViewColor.textSecondary)
        }
        .padding(BaseViewLayout.badgeInset)
        .background(BaseViewColor.elevatedSurface)
        .overlay(
            Rectangle()
                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
    }
}
