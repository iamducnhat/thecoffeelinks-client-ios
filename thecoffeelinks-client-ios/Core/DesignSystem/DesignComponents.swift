//
//  DesignComponents.swift
//  thecoffeelinks-client-ios
//
//  Magazine/Notion-style editorial components
//

import SwiftUI

// MARK: - Spacing (Re-export from Editorial)

enum Spacing {
    static let xxs: CGFloat = Editorial.Spacing.xxs
    static let xs: CGFloat = Editorial.Spacing.xs
    static let sm: CGFloat = Editorial.Spacing.sm
    static let md: CGFloat = Editorial.Spacing.md
    static let lg: CGFloat = Editorial.Spacing.lg
    static let xl: CGFloat = Editorial.Spacing.xl
    static let xxl: CGFloat = Editorial.Spacing.xxl
}

// MARK: - Radius

enum Radius {
    static let sm: CGFloat = 0
    static let md: CGFloat = 0
    static let lg: CGFloat = 0
    static let xl: CGFloat = 0
    static let full: CGFloat = 9999
}

// MARK: - Glass Card (Legacy - now Editorial Card)

struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}

// MARK: - Glass Primary Button (Legacy - now Editorial Button)

struct GlassPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let tintColor: Color
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        tint: Color = Editorial.Colors.accent,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.tintColor = tint
        self.action = action
    }
    
    var body: some View {
        EditorialButton(title: title, isLoading: isLoading, isDisabled: isDisabled, action: action)
    }
}

// MARK: - Glass Secondary Button (Legacy)

struct GlassSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        EditorialSecondaryButton(title: title, action: action)
    }
}

// MARK: - Skeleton Loading

struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    @State private var isAnimating = false
    
    init(width: CGFloat? = nil, height: CGFloat = 20) {
        self.width = width
        self.height = height
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: Radius.sm)
            .fill(Color(UIColor.secondarySystemBackground))
            .frame(width: width, height: height)
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        EditorialEmptyState(
            title: title,
            message: message,
            actionTitle: actionTitle,
            action: action
        )
    }
}

struct EditorialEmptyState: View {
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Editorial.Spacing.md) {
            Image(systemName: "square.dashed")
                .font(.system(size: 48))
                .foregroundStyle(Editorial.Colors.textTertiary)
            
            Text(title)
                .font(Editorial.heading())
                .foregroundStyle(Editorial.Colors.textPrimary)
            
            Text(message)
                .font(Editorial.body())
                .foregroundStyle(Editorial.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Editorial.body())
                        .fontWeight(.medium)
                        .foregroundStyle(Editorial.Colors.accent)
                }
                .padding(.top, Editorial.Spacing.sm)
            }
        }
        .padding(Editorial.Spacing.xl)
    }
}



// MARK: - Loading View

struct LoadingView: View {
    let message: String?
    
    init(_ message: String? = nil) { self.message = message }
    
    var body: some View {
        VStack(spacing: Editorial.Spacing.grid * 2) {
            ProgressView()
                .controlSize(.large)
            if let message = message {
                Text(message)
                    .font(Editorial.uiCaption())
                    .foregroundStyle(Editorial.Colors.secondaryLabel)
            }
        }
    }
}

// MARK: - Badge

struct Badge: View {
    let text: String
    let style: BadgeStyle
    
    enum BadgeStyle {
        case primary, success, warning, danger, premium
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Editorial.Colors.primaryEspresso
            case .success: return .green
            case .warning: return .orange
            case .danger: return .red
            case .premium: return .yellow
            }
        }
        
        var foregroundColor: Color {
            self == .premium ? .black : .white
        }
    }
    
    var body: some View {
        Text(text)
            .font(Editorial.uiMicro())
            .fontWeight(.medium)
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, Editorial.Spacing.grid)
            .padding(.vertical, 4)
            .background(style.backgroundColor, in: Capsule())
    }
}

// MARK: - Quantity Stepper

struct QuantityStepper: View {
    @Binding var quantity: Int
    let minValue: Int
    let maxValue: Int
    let onDelete: (() -> Void)?
    
    init(quantity: Binding<Int>, min: Int = 1, max: Int = 99, onDelete: (() -> Void)? = nil) {
        self._quantity = quantity
        self.minValue = min
        self.maxValue = max
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                if quantity > minValue { quantity -= 1 }
                else if let onDelete = onDelete { onDelete() }
            } label: {
                Image(systemName: quantity <= minValue && onDelete != nil ? "trash" : "minus")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 36, height: 36)
            }
            .foregroundStyle(quantity <= minValue && onDelete != nil ? .red : Editorial.Colors.label)
            
            Text("\(quantity)")
                .font(Editorial.uiBody())
                .fontWeight(.medium)
                .frame(minWidth: 36)
            
            Button {
                if quantity < maxValue { quantity += 1 }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 36, height: 36)
            }
            .disabled(quantity >= maxValue)
            .foregroundStyle(Editorial.Colors.label)
        }
        .background(Color(UIColor.secondarySystemBackground), in: Capsule())
    }
}

// MARK: - Font Extension (Legacy compatibility)

extension Font {
    static func brandSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    static func brandRounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
