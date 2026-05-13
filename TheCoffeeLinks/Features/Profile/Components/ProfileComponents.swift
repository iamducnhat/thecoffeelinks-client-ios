//
//  ProfileComponents.swift
//  thecoffeelinks-client-ios
//
//  Created for Profile Feature
//

import SwiftUI

// MARK: - Profile Navigation Header
struct ProfileNavigationHeader<Trailing: View>: View {
    let title: String
    let onBack: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing
    }

    var body: some View {
        ZStack {
            Text(title)
                .font(BaseViewFont.screenTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(BaseViewColor.accentForeground)
                        .frame(width: BaseViewLayout.navButtonSize, height: BaseViewLayout.navButtonSize)
                        .background(BaseViewColor.accent)
                }
                .buttonStyle(.plain)

                Spacer()

                trailing()
            }
        }
        .frame(height: BaseViewLayout.navButtonSize)
        .padding(.horizontal, BaseViewLayout.screenInset)
        .padding(.top, BaseViewLayout.screenTopInset)
        .padding(.bottom, BaseViewLayout.screenTopInset)
    }
}

extension ProfileNavigationHeader where Trailing == EmptyView {
    init(title: String, onBack: @escaping () -> Void) {
        self.init(title: title, onBack: onBack) {
            EmptyView()
        }
    }
}

// MARK: - Metric Box (Points / Vouchers)
struct MetricBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(BaseViewFont.sectionTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
            Text(label)
                .font(BaseViewFont.label)
                .foregroundStyle(BaseViewColor.textSecondary)
        }
        .padding(BaseViewLayout.badgeInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BaseViewColor.elevatedSurface)
        .overlay(
            Rectangle()
                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
    }
}

// MARK: - Profile Section Header
struct ProfileSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .textCase(.uppercase)
            .font(BaseViewFont.labelStrong)
            .foregroundStyle(BaseViewColor.textPrimary)
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
                .foregroundStyle(BaseViewColor.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(BaseViewFont.body)
                .foregroundStyle(BaseViewColor.textPrimary)
            
            Spacer()
            
            Image("chevron_right")
                .font(.system(size: 14))
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

// MARK: - Toggle Row (for Settings)
struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: AppLayout.spacing) {
            Image(icon)
                .font(.system(size: 20))
                .foregroundStyle(BaseViewColor.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(BaseViewFont.body)
                .foregroundStyle(BaseViewColor.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(BaseViewColor.accent)
                .accessibilityIdentifier(title)
                .accessibilityLabel(title)
        }
        .padding(BaseViewLayout.badgeInset)
        .background(BaseViewColor.elevatedSurface)
        .overlay(
            Rectangle()
                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
    }
}
