import SwiftUI

/// Receipt-Editorial Design System: Layout & Spacing
/// Derived from canonical CheckoutView.swift
/// 
/// BASE UNIT: 18pt (not 8pt)
/// CORNER RADIUS: 4pt (uniform, retro receipt feel)
/// STYLE: .continuous (smooth modern corners)

struct AppLayout {
    
    // MARK: - Base Grid
    
    /// Primary spacing unit: 18pt (derived from CheckoutView)
    static let unit: CGFloat = 18.0
    
    /// Half unit for small gaps: 9pt
    static let halfUnit: CGFloat = 9.0
    
    // MARK: - Spacing Tokens
    
    /// Micro spacing: 4pt (button internal padding)
    static let spacingMicro: CGFloat = 4.0
    
    /// Small spacing: 6pt (stepper button gaps)
    static let spacingSmall: CGFloat = 6.0
    
    /// Compact spacing: 8pt (vertical padding in inputs)
    static let spacingCompact: CGFloat = 8.0
    
    /// Medium spacing: 12pt (item internal gaps)
    static let spacingMedium: CGFloat = 12.0
    
    /// Standard spacing: 18pt (section gaps, screen padding)
    static let spacing: CGFloat = 18.0
    
    /// Large spacing: 24pt (header padding, major sections)
    static let spacingLarge: CGFloat = 24.0
    
    /// Extra large: 32pt (section separators)
    static let spacingXL: CGFloat = 32.0
    
    // MARK: - Screen Margins
    
    /// Primary screen edge padding: 18pt
    static let margin: CGFloat = 18.0
    
    /// Relaxed screen edge padding: 24pt
    static let marginRelaxed: CGFloat = 24.0
    
    // MARK: - Components
    
    /// Universal corner radius: 4pt (retro receipt style)
    static let cornerRadius: CGFloat = 4.0
    
    /// Corner style for all rounded rectangles
    static let cornerStyle: RoundedCornerStyle = .continuous
    
    /// Minimum touch target: 44pt
    static let touchTarget: CGFloat = 44.0
    
    /// Product image size: 80pt
    static let productImageSize: CGFloat = 80.0
    
    /// Stepper button size: internal padding 4pt
    static let stepperPadding: CGFloat = 4.0
    
    /// Quantity display min width: 36pt
    static let quantityMinWidth: CGFloat = 36.0
    
    /// Wave separator step width: 18pt
    static let waveStepWidth: CGFloat = 18.0
    
    // MARK: - Border
    
    /// Standard border width: 1pt
    static let borderWidth: CGFloat = 1.0
    
    /// Dashed border pattern
    static let dashedPattern: [CGFloat] = [2]
    
    // MARK: - Legacy Aliases (Compatibility)
    
    /// Legacy: 8pt grid
    static let grid: CGFloat = 8.0
    
    /// Legacy: Small spacing
    static let spacingCocoa: CGFloat = spacingMicro
    
    /// Legacy: Standard spacing
    static let spacingEspresso: CGFloat = spacingCompact
    
    /// Legacy: Card gutter
    static let spacingEditorial: CGFloat = spacing
    
    /// Legacy: Section separation
    static let spacingCappuccino: CGFloat = spacingXL
    
    /// Legacy: Major section
    static let spacingMocha: CGFloat = 48.0
    
    /// Legacy: Standard radius
    static let radius: CGFloat = cornerRadius
    
    /// Legacy: Button radius
    static let radiusButton: CGFloat = cornerRadius
    
    /// Legacy: Button height
    static let buttonHeight: CGFloat = 48.0
    
    /// Legacy: Icon size
    static let iconSize: CGFloat = 24.0
    
    /// Legacy: Margins
    static let marginCompact: CGFloat = 16.0
}

// MARK: - Convenience Extensions

extension View {
    /// Apply standard screen padding (18pt horizontal)
    func screenPadding() -> some View {
        self.padding(.horizontal, AppLayout.margin)
    }
    
    /// Apply relaxed screen padding (24pt horizontal)
    func screenPaddingRelaxed() -> some View {
        self.padding(.horizontal, AppLayout.marginRelaxed)
    }
    
    /// Apply standard section spacing
    func sectionSpacing() -> some View {
        self.padding(.vertical, AppLayout.spacing)
    }
}
