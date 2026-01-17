//
//  EditorialLayout.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design System
//  Consumer-Facing Coffee Application
//  Derived from canonical CheckoutView.swift
//

import SwiftUI

// MARK: - Editorial Design System (Compatibility Layer)

struct Editorial {
    
    // MARK: - Typography Scale
    
    /// Display H1 - Screen Titles (Serif, Bold)
    static func displayH1() -> Font { AppFont.displayTitle }
    
    /// Display H2 - Section Headers (Serif, Semibold)
    static func displayH2() -> Font { AppFont.sectionHeader }
    
    /// UI Title (Headline)
    static func uiTitle() -> Font { AppFont.headline }
    
    /// UI Body (Default)
    static func uiBody() -> Font { AppFont.body }
    
    /// UI Caption (Callout)
    static func uiCaption() -> Font { AppFont.uiCaption }
    
    /// UI Micro (Caption, Medium)
    static func uiMicro() -> Font { AppFont.uiMicro }
    
    /// UI Button (Semibold)
    static func uiButton() -> Font { AppFont.uiButton }
    
    // MARK: - Aliases
    static func title() -> Font { displayH1() }
    static func heading() -> Font { displayH2() }
    static func subheading() -> Font { uiTitle() }
    static func body() -> Font { uiBody() }
    static func caption() -> Font { uiCaption() }
    static func metadata() -> Font { uiMicro() }
    
    // MARK: - Color System
    
    struct Colors {
        static let primaryEspresso = Color.primaryEspresso
        static let secondaryLatte = Color.secondaryLatte
        static let backgroundPaper = Color.backgroundPaper
        static let surfaceCard = Color.surfaceCard
        static let textInk = Color.textInk
        static let textMuted = Color.textMuted
        static let semanticError = Color.semanticError
        static let semanticSuccess = Color.semanticSuccess
        static let semanticWarning = Color.semanticWarning
        static let border = Color.border
        
        // Terminal Colors (Legacy)
        static let primaryTerminal = Color.primaryTerminal
        static let backgroundTerminal = Color.backgroundTerminal
        static let surfaceTerminal = Color.surfaceTerminal
        static let accentTerminal = Color.accentTerminal
        
        // Aliases
        static let background = Color.backgroundPaper
        static let secondaryBackground = Color.surfaceCard
        static let label = Color.textInk
        static let secondaryLabel = Color.textMuted
        static let separator = Color.border
        static let accent = primaryEspresso
        static let textPrimary = textInk
        static let textSecondary = textMuted
        static let textTertiary = Color.textTertiary
    }
    
    // MARK: - Spacing (18pt Grid)
    
    struct Spacing {
        static let grid: CGFloat = AppLayout.unit
        static let margin: CGFloat = AppLayout.margin
        static let gutter: CGFloat = AppLayout.spacingMedium
        
        static let sectionToSection: CGFloat = AppLayout.spacingXL
        static let largeSection: CGFloat = 48
        
        static let xxs: CGFloat = AppLayout.spacingMicro
        static let xs: CGFloat = AppLayout.spacingSmall
        static let sm: CGFloat = AppLayout.spacingCompact
        static let md: CGFloat = AppLayout.spacingMedium
        static let lg: CGFloat = AppLayout.spacing
        static let xl: CGFloat = AppLayout.spacingLarge
        static let xxl: CGFloat = 48
        static let sectionGap: CGFloat = AppLayout.spacingXL
        static let pageMargin: CGFloat = AppLayout.marginRelaxed
    }
    
    // MARK: - Component Specs
    
    struct Component {
        static let buttonHeight: CGFloat = 48
        static let buttonCornerRadius: CGFloat = AppLayout.cornerRadius
        static let cardCornerRadius: CGFloat = AppLayout.cornerRadius
        static let inputHeight: CGFloat = 48
        static let touchTarget: CGFloat = AppLayout.touchTarget
        static let borderWidth: CGFloat = AppLayout.borderWidth
    }
}

// MARK: - Editorial Components (Updated for Receipt Style)

struct EditorialButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        ReceiptPrimaryButton(
            title: title,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
}

struct EditorialSecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.uiButton)
                .foregroundStyle(Color.primaryEspresso)
                .frame(maxWidth: .infinity)
                .frame(height: Editorial.Component.buttonHeight)
                .background(Color.backgroundPaper)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(Color.border, lineWidth: AppLayout.borderWidth)
                )
        }
    }
}

struct EditorialCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Editorial.Spacing.gutter)
            .background(Color.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(Color.border, lineWidth: AppLayout.borderWidth)
            )
            .cornerRadius(AppLayout.cornerRadius)
    }
}

struct EditorialTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: Editorial.Spacing.gutter) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(Color.textMuted)
            }
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.textMuted))
                .font(AppFont.body)
                .keyboardType(keyboardType)
                .foregroundStyle(Color.textInk)
        }
        .padding(.horizontal, Editorial.Spacing.gutter)
        .frame(height: Editorial.Component.inputHeight)
        .background(Color.backgroundPaper)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: AppLayout.borderWidth)
        )
    }
}

struct EditorialToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(AppFont.body)
                .foregroundStyle(Color.textInk)
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.primaryEspresso))
        .padding(Editorial.Spacing.gutter)
        .background(Color.backgroundPaper)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: AppLayout.borderWidth)
        )
    }
}

struct EditorialStepperRow: View {
    let title: String
    let value: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.body)
                .foregroundStyle(Color.textInk)
            
            Spacer()
            
            HStack(spacing: 0) {
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .frame(width: 32, height: 32)
                        .background(Color.surfaceCard)
                }
                .foregroundColor(Color.primaryEspresso)
                
                Text(value)
                    .font(AppFont.body)
                    .fontWeight(.medium)
                    .frame(width: 60, height: 32)
                    .background(Color.backgroundPaper)
                
                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .frame(width: 32, height: 32)
                        .background(Color.surfaceCard)
                }
                .foregroundColor(Color.primaryEspresso)
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(Color.border, lineWidth: AppLayout.borderWidth)
            )
        }
        .padding(Editorial.Spacing.md)
        .background(Color.backgroundPaper)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: AppLayout.borderWidth)
        )
    }
}

struct EditorialDivider: View {
    var body: some View {
        ReceiptDivider(color: Color.border)
    }
}

struct EditorialPermissionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Editorial.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isGranted ? Color.semanticSuccess : Color.textInk)
                    .frame(width: 40, height: 40)
                    .background(isGranted ? Color.semanticSuccess.opacity(0.1) : Color.backgroundPaper)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(isGranted ? Color.semanticSuccess : Color.border, lineWidth: AppLayout.borderWidth)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFont.headline)
                        .foregroundStyle(Color.textInk)
                    
                    Text(subtitle)
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.textMuted)
                }
                
                Spacer()
                
                if isGranted {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.semanticSuccess)
                } else {
                    Text("Enable")
                        .font(AppFont.uiButton)
                        .foregroundStyle(Color.primaryEspresso)
                }
            }
            .padding(Editorial.Spacing.gutter)
            .background(Color.backgroundPaper)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(isGranted ? Color.semanticSuccess : Color.border, lineWidth: AppLayout.borderWidth)
            )
        }
        .disabled(isGranted)
    }
}

struct EditorialSelectableRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(isSelected ? Color.textInk : Color.textMuted)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.primaryEspresso)
                }
            }
            .padding(Editorial.Spacing.gutter)
            .background(isSelected ? Color.primaryEspresso.opacity(0.1) : Color.backgroundPaper)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(isSelected ? Color.primaryEspresso : Color.border, lineWidth: AppLayout.borderWidth)
            )
        }
    }
}

struct EditorialCategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.uiMicro)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Color.backgroundPaper : Color.textInk)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primaryEspresso : Color.backgroundPaper)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(Color.primaryEspresso, lineWidth: AppLayout.borderWidth)
                )
                .cornerRadius(AppLayout.cornerRadius)
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color.textInk
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFont.uiCaption)
                .foregroundStyle(isTotal ? Color.textInk : Color.textMuted)
            Spacer()
            Text(value)
                .font(isTotal ? AppFont.headline : AppFont.uiCaption)
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isTotal ? Color.surfaceCard : Color.backgroundPaper)
    }
}

// View Extensions
extension View {
    func editorialBackground() -> some View {
        self.background(Color.backgroundPaper.ignoresSafeArea())
    }
    
    func editorialPadding() -> some View {
        self.padding(.horizontal, Editorial.Spacing.margin)
    }
}
