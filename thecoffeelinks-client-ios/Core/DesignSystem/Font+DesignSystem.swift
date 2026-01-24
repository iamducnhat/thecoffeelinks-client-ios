import SwiftUI

/// Typography Design System
/// Uses Geologica for UI and Noto Sans Mono for monospace contexts
///
/// TYPOGRAPHY HIERARCHY:
///
/// 1. DISPLAY (Large titles, headings)
///    - Screen titles (H1): Geologica, 28pt, Bold
///    - Section headers (H2): Geologica, 20pt, Medium
///    - Total label: Geologica, 28pt, Medium
///
/// 2. MONOSPACE (Prices, Quantities, Codes, IDs)
///    - Prices: Noto Sans Mono, 17pt, Regular
///    - Quantities: Noto Sans Mono, 17pt, Medium
///    - Total price: Noto Sans Mono, 28pt, Medium
///    - CTA buttons: Noto Sans Mono, 22pt, Medium
///    - Small labels: Noto Sans Mono, 12pt, Regular
///
/// 3. BODY (Standard UI text)
///    - Body text: Geologica, 17pt, Regular
///    - Headlines: Geologica, 17pt, Medium
///    - Navigation: Geologica, 22pt, Medium

struct AppFont {
    
    // MARK: - Display Tokens (Headlines)
    
    /// Screen title: "Checkout"
    /// Font: Geologica-Bold, 28pt
    static var displayTitle: Font {
        .custom("GeologicaThinRoman-Bold", size: 28)
    }
    
    /// Section header: "ORDER TYPE", "VOUCHER"
    /// Font: Geologica-Medium, 20pt
    static var sectionHeader: Font {
        .custom("GeologicaThinRoman-Medium", size: 20)
    }
    
    /// Total label: "TOTAL"
    /// Font: Geologica-Medium, 28pt
    static var totalLabel: Font {
        .custom("GeologicaThinRoman-Medium", size: 28)
    }
    
    // MARK: - Monospace Tokens (Prices, Quantities, Codes, IDs)
    
    /// Prices in lists: "10.000₫"
    /// Font: NotoSansMono-Regular, 17pt
    static var monoBody: Font {
        .custom("NotoSansMono-Regular", size: 17)
    }
    
    /// Quantity display: "1"
    /// Font: NotoSansMono-Medium, 17pt
    static var monoHeadline: Font {
        .custom("NotoSansMono-Medium", size: 17)
    }
    
    /// Total price: "12.000.000₫"
    /// Font: NotoSansMono-Medium, 28pt
    static var monoTitle: Font {
        .custom("NotoSansMono-Medium", size: 28)
    }
    
    /// CTA button text: "Place Order"
    /// Font: NotoSansMono-Medium, 22pt
    static var monoCTA: Font {
        .custom("NotoSansMono-Medium", size: 22)
    }
    
    /// Small labels: button icons
    /// Font: NotoSansMono-Regular, 12pt
    static var monoCaption: Font {
        .custom("NotoSansMono-Regular", size: 12)
    }
    
    // MARK: - Body Tokens (Standard UI Text)
    
    /// Standard body text
    /// Font: Geologica-Regular, 17pt
    static var body: Font {
        .custom("GeologicaThinRoman-Regular", size: 17)
    }
    
    /// Product name in list
    /// Font: Geologica-Medium, 17pt
    static var headline: Font {
        .custom("GeologicaThinRoman-Medium", size: 17)
    }
    
    /// Navigation title
    /// Font: Geologica-Medium, 22pt
    static var navIcon: Font {
        .custom("GeologicaThinRoman-Medium", size: 22)
    }
    
    /// Product Title
    /// Font: Geologica-Bold, Size: AppLayout.unit (18pt)
    static var productTitle: Font {
        .custom("GeologicaThinRoman-Bold", size: AppLayout.unit)
    }
    
    // MARK: - Legacy Aliases (Compatibility)
    
    static let serifFontName = "GeologicaThinRoman-Regular"
    static let serifBoldFontName = "GeologicaThinRoman-Bold"
    static let serifItalicFontName = "GeologicaThinRoman-Regular" // No italic variant present
    
    static var displayH1: Font { displayTitle }
    static var displayH2: Font { sectionHeader }
    static var uiTitle: Font { headline }
    static var uiBody: Font { body }
    static var uiCaption: Font { .custom("GeologicaThinRoman-Regular", size: 16) }
    static var uiMicro: Font { .custom("GeologicaThinRoman-Medium", size: 12) }
    static var uiButton: Font { .custom("GeologicaThinRoman-SemiBold", size: 17) }
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
