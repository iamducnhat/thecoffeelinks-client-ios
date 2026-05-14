import SwiftUI

/// BaseView Design System: Button Components
/// Derived from canonical CheckoutView.swift
///
/// BUTTON HIERARCHY:
///
/// 1. PRIMARY CTA (One per screen)
///    - Background: accentColor
///    - Text: .background (white/black)
///    - Font: monoCTA
///    - Radius: 4pt
///
/// 2. UTILITY BUTTON (Actions like mode toggle, quantity controls)
///    - Background: .primary (inverted)
///    - Text: .background
///    - Font: monoBody
///    - Radius: 4pt
///    - Padding: 4pt
///
/// 3. GHOST BUTTON (Tertiary actions)
///    - Background: none
///    - Text: .secondary
///    - Stroke: optional

// MARK: - Primary CTA Button

struct ReceiptPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        AppButton(
            title,
            style: .primary,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
}

// MARK: - Utility Button (Mode Toggle, Actions)

struct ReceiptUtilityButton: View {
    let title: String
    var icon: String? = nil
    var isSelected: Bool = false
    let action: () -> Void
    
    var body: some View {
        AppButton(
            title,
            icon: icon,
            style: isSelected ? .primary : .secondary,
            fillsWidth: false,
            action: action
        )
    }
}

// MARK: - Quantity Stepper Buttons

struct ReceiptStepperButton: View {
    let icon: String
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        AppButton(icon: icon, isDisabled: isDisabled, action: action)
    }
}

// MARK: - Icon Button (Back, Close)

struct ReceiptIconButton: View {
    let icon: String
    var showBorder: Bool = false
    var borderOpacity: Double = 1.0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            IconView(name: icon)
                .font(BaseViewFont.navIcon)
                .foregroundStyle(BaseViewColor.textPrimary)
                .frame(minWidth: BaseViewLayout.touchTarget, minHeight: BaseViewLayout.touchTarget)
                .background {
                    if showBorder {
                        RoundedRectangle(cornerRadius: BaseViewLayout.cornerRadius, style: BaseViewLayout.cornerStyle)
                            .fill(BaseViewColor.background)
                            .opacity(borderOpacity)
                    }
                }
                .overlay {
                    if showBorder {
                        RoundedRectangle(cornerRadius: BaseViewLayout.cornerRadius, style: BaseViewLayout.cornerStyle)
                            .strokeBorder(BaseViewColor.textPrimary, lineWidth: BaseViewLayout.borderWidth)
                            .opacity(borderOpacity)
                    }
                }
        }
    }
}

// MARK: - Legacy Components (Compatibility)

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        ReceiptPrimaryButton(title: title, isLoading: isLoading, action: action)
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(icon)
                }
                Text(title)
                    .font(BaseViewFont.uiBody)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(BaseViewColor.background)
            .foregroundColor(BaseViewColor.accent)
            .cornerRadius(BaseViewLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: BaseViewLayout.cornerRadius, style: BaseViewLayout.cornerStyle)
                    .strokeBorder(BaseViewColor.accent, lineWidth: 1)
            )
        }
    }
}

struct GhostButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BaseViewFont.uiCaption)
                .fontWeight(.medium)
                .foregroundColor(BaseViewColor.textSecondary)
                .padding(.vertical, 8)
        }
    }
}
