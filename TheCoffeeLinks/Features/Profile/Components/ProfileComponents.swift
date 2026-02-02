//
//  ProfileComponents.swift
//  thecoffeelinks-client-ios
//
//  Created for Profile Feature
//

import SwiftUI

// MARK: - Metric Box (Points / Vouchers)
struct MetricBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(AppFont.monoTitle)
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(AppFont.uiMicro)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(AppLayout.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfacePrimary)
        .overlay(
            Capsule()
                .strokeBorder(Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Profile Section Header
struct ProfileSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .textCase(.uppercase)
            .font(AppFont.sectionHeader)
            .foregroundStyle(Color.textPrimary)
    }
}

// MARK: - Profile Row
// Supports both Navigation and Button actions
struct ProfileRow<Destination: View>: View {
    let title: String
    let icon: String
    var destination: Destination? = nil // Optional destination for NavigationLink
    var action: (() -> Void)? = nil    // Optional action for Button
    
    init(title: String, icon: String, destination: Destination) {
        self.title = title
        self.icon = icon
        self.destination = destination
        self.action = nil
    }
    
    init(title: String, icon: String, action: @escaping () -> Void) where Destination == EmptyView {
        self.title = title
        self.icon = icon
        self.destination = nil
        self.action = action
    }
    
    var body: some View {
        if let destination = destination {
            NavigationLink(destination: destination) {
                rowContent
            }
        } else if let action = action {
            Button(action: action) {
                rowContent
            }
        } else {
            rowContent // Fallback, just static
        }
    }
    
    private var rowContent: some View {
        HStack(spacing: AppLayout.spacing) {
            Image(icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(AppFont.body)
                .foregroundStyle(Color.textPrimary)
            
            Spacer()
            
            Image("chevron_right")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(AppLayout.spacing)
        .background(Color.bgPrimary)
        // Note: No border here to allow stacking in a group if needed, 
        // but design usually has them as list items.
        // If we want grouped style with separators, we might need a container.
        // For now, let's keep the row simple. The container will handle borders if needed.
        // Or we can add a bottom divider.
    }
}

// MARK: - Toggle Row (for Settings)
struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: AppLayout.spacing) {
            Image(icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(AppFont.body)
                .foregroundStyle(Color.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.accentPrimary)
                .accessibilityIdentifier(title)
                .accessibilityLabel(title)
        }
        .padding(AppLayout.spacing)
        .background(Color.bgPrimary)
        .overlay(
            Capsule()
                .strokeBorder(Color.border, lineWidth: 1)
        )
    }
}
