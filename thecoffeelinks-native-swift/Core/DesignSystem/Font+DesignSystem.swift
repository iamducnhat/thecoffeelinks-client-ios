import SwiftUI

/// Receipt-Editorial Design System: Typography
/// Derived from canonical CheckoutView.swift
///
/// TYPOGRAPHY HIERARCHY:
///
/// 1. SERIF (Libre Baskerville / System Serif)
///    - Screen titles (H1): .title, .serif, .bold
///    - Section headers (H2): .title3, .serif, .semibold
///    - TOTAL label: .title, .serif, .semibold
///
/// 2. MONOSPACED (System Mono)
///    - Prices: .body, .monospaced
///    - Quantities: .headline, .monospaced
///    - Total price: .title, .monospaced, .semibold
///    - Toggle labels: .body, .monospaced
///    - Promo codes: .body, .monospaced
///    - Icon buttons: .caption, .monospaced
///
/// 3. DEFAULT (System / SF Pro)
///    - Body text: .body, .default
///    - Descriptions: .body, .default
///    - Placeholder text: .body, .default

struct AppFont {
    
    // MARK: - Serif Tokens (Headlines Only)
    
    /// Screen title: "Checkout"
    /// Font: System Serif, Title size, Bold weight
    static var displayTitle: Font {
        .system(.title, design: .serif).weight(.bold)
    }
    
    /// Section header: "ORDER TYPE", "VOUCHER"
    /// Font: System Serif, Title3 size, Medium weight
    static var sectionHeader: Font {
        .system(.title3, design: .serif).weight(.medium)
    }
    
    /// Total label: "TOTAL"
    /// Font: System Serif, Title size, Medium weight
    static var totalLabel: Font {
        .system(.title, design: .serif).weight(.medium)
    }
    
    // MARK: - Monospaced Tokens (Prices, Quantities, Codes)
    
    /// Prices in lists: "10.000₫"
    /// Font: System Mono, Body size
    static var monoBody: Font {
        .system(.body, design: .monospaced)
    }
    
    /// Quantity display: "1"
    /// Font: System Mono, Headline size, Medium weight
    static var monoHeadline: Font {
        .system(.headline, design: .monospaced).weight(.medium)
    }
    
    /// Total price: "12.000.000₫"
    /// Font: System Mono, Title size, Medium weight
    static var monoTitle: Font {
        .system(.title, design: .monospaced).weight(.medium)
    }
    
    /// CTA button text: "Place Order"
    /// Font: System Mono, Title2 size, Medium weight
    static var monoCTA: Font {
        .system(.title2, design: .monospaced).weight(.medium)
    }
    
    /// Small mono for icons: button icons
    /// Font: System Mono, Caption size
    static var monoCaption: Font {
        .system(.caption, design: .monospaced)
    }
    
    // MARK: - Default Tokens (Body Text)
    
    /// Standard body text
    /// Font: System Default, Body size
    static var body: Font {
        .system(.body, design: .default)
    }
    
    /// Product name in list
    /// Font: System Default, Headline size, Medium weight
    static var headline: Font {
        .system(.headline, design: .default).weight(.medium)
    }
    
    /// Navigation title (back button weight)
    /// Font: System Default, Title2 size, Medium weight
    static var navIcon: Font {
        .system(.title2).weight(.medium)
    }
    
    /// Editorial Product Title
    /// Font: Libre Baskerville Bold, Size: AppLayout.unit (18pt)
    static var productTitle: Font {
        .custom(serifBoldFontName, size: AppLayout.unit)
    }
    
    // MARK: - Legacy Aliases (Compatibility)
    
    static let serifFontName = "LibreBaskerville-Regular"
    static let serifBoldFontName = "LibreBaskerville-Bold"
    static let serifItalicFontName = "LibreBaskerville-Italic"
    
    static var displayH1: Font { displayTitle }
    static var displayH2: Font { sectionHeader }
    static var uiTitle: Font { headline }
    static var uiBody: Font { body }
    static var uiCaption: Font { .system(.callout, design: .default) }
    static var uiMicro: Font { .system(.caption, design: .default).weight(.medium) }
    static var uiButton: Font { .system(.body, design: .default).weight(.semibold) }
    static var mono: Font { monoBody }
}

// MARK: - View Modifiers

extension View {
    func fontDisplayTitle() -> some View {
        self.font(AppFont.displayTitle)
    }
    
    func fontSectionHeader() -> some View {
        self.font(AppFont.sectionHeader)
    }
    
    func fontMonoBody() -> some View {
        self.font(AppFont.monoBody)
    }
    
    func fontMonoHeadline() -> some View {
        self.font(AppFont.monoHeadline)
    }
    
    func fontMonoTitle() -> some View {
        self.font(AppFont.monoTitle)
    }
    
    func fontBody() -> some View {
        self.font(AppFont.body)
    }
    
    // Legacy modifiers
    func fontH1() -> some View { self.font(AppFont.displayH1) }
    func fontH2() -> some View { self.font(AppFont.displayH2) }
    func fontTitle() -> some View { self.font(AppFont.uiTitle) }
    func fontCaption() -> some View { self.font(AppFont.uiCaption) }
    func fontMicro() -> some View { self.font(AppFont.uiMicro) }
    func fontButton() -> some View { self.font(AppFont.uiButton) }
}
