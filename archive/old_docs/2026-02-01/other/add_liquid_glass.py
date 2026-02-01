#!/usr/bin/env python3
"""
Append Liquid Glass components to DesignSystem.swift
"""

liquid_glass_code = """

// MARK: - Liquid Glass Components (iOS 26)

// MARK: - Liquid Glass Card

struct LiquidGlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    
    init(cornerRadius: CGFloat = 20, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Liquid Glass TextField

struct LiquidGlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isFocused ? Color.forestCanopy : Color.neutral400)
                    .frame(width: 24)
            }
            
            TextField(placeholder, text: $text)
                .font(.brandSans(16))
                .autocorrectionDisabled()
                .focused($isFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isFocused ?
                        LinearGradient(
                            colors: [Color.forestCanopy.opacity(0.5), Color.forestCanopy.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: isFocused ? Color.forestCanopy.opacity(0.15) : Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Liquid Glass Secure Field

struct LiquidGlassSecureField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = "lock.fill"
    @Binding var showPassword: Bool
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isFocused ? Color.forestCanopy : Color.neutral400)
                .frame(width: 24)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .font(.brandSans(16))
                    .autocorrectionDisabled()
                    .focused($isFocused)
            } else {
                SecureField(placeholder, text: $text)
                    .font(.brandSans(16))
                    .focused($isFocused)
            }
            
            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.neutral400)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isFocused ?
                        LinearGradient(
                            colors: [Color.forestCanopy.opacity(0.5), Color.forestCanopy.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: isFocused ? Color.forestCanopy.opacity(0.15) : Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Liquid Glass Button

enum LiquidGlassButtonStyle {
    case primary
    case secondary
    case ghost
}

struct LiquidGlassButton: View {
    let title: String
    let icon: String?
    let style: LiquidGlassButtonStyle
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(_ title: String, icon: String? = nil, style: LiquidGlassButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.brandSerif(16))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(backgroundView)
            .foregroundStyle(foregroundColor)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.forestCanopy)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: Color.forestCanopy.opacity(0.4), radius: 12, x: 0, y: 4)
            
        case .secondary:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.forestCanopy.opacity(0.4), Color.forestCanopy.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            
        case .ghost:
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return Color.forestCanopy
        case .ghost:
            return Color.forestCanopy
        }
    }
}

// MARK: - Liquid Glass Search Bar

struct LiquidGlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isFocused ? Color.forestCanopy : Color.neutral400)
            
            TextField(placeholder, text: $text)
                .font(.brandSans(16))
                .autocorrectionDisabled()
                .focused($isFocused)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.neutral400)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        isFocused ?
                        LinearGradient(
                            colors: [Color.forestCanopy.opacity(0.4), Color.forestCanopy.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: isFocused ? Color.forestCanopy.opacity(0.12) : Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
"""

# Read the current file
with open('thecoffeelinks-client-ios/DesignSystem.swift', 'r') as f:
    content = f.read()

# Append the Liquid Glass components
with open('thecoffeelinks-client-ios/DesignSystem.swift', 'w') as f:
    f.write(content + liquid_glass_code)

print("✅ Liquid Glass components added to DesignSystem.swift")
