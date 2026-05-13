//
//  ReceiptComponents.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design System: Shared UI Components
//  Derived from canonical CheckoutView.swift
//

import SwiftUI

// MARK: - Wave Separator (Zig-Zag Tear Effect)

/// Zig-zag line separator mimicking receipt paper tear
struct WaveSeparator: Shape {
    var stepWidth: CGFloat = 4.0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let h = stepWidth / 2
        let midY = rect.midY
        
        let count = Int(ceil(rect.width / stepWidth)) + 2
        let total = CGFloat(count) * stepWidth
        let startX = (rect.width - total) / 2
        
        path.move(to: CGPoint(x: startX, y: midY - h))
        
        for i in 1...count {
            let x = startX + CGFloat(i) * stepWidth
            let y = (i % 2 == 0) ? midY - h : midY + h
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

/// Filled rectangle with wave edge (for backgrounds)
struct WaveRect: Shape {
    var stepWidth: CGFloat = 4.0
    var waveEdge: WaveEdge = .top
    
    enum WaveEdge {
        case top, bottom, left, right
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h = stepWidth / 2
        
        switch waveEdge {
        case .top:
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            addHorizontalWave(&path, rect: rect, y: rect.minY, h: h)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
            
        case .bottom:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            addHorizontalWave(&path, rect: rect, y: rect.maxY, h: -h)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
            
        case .left:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            addVerticalWave(&path, rect: rect, x: rect.minX, h: h)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
            
        case .right:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            addVerticalWave(&path, rect: rect, x: rect.maxX, h: -h)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        
        return path
    }
    
    private func addHorizontalWave(_ path: inout Path, rect: CGRect, y: CGFloat, h: CGFloat) {
        let count = Int(ceil(rect.width / stepWidth)) + 2
        let total = CGFloat(count) * stepWidth
        let startX = rect.midX - total / 2
        
        path.addLine(to: CGPoint(x: startX, y: y))
        
        for i in 1...count {
            let x = startX + CGFloat(i) * stepWidth
            let yPos = y + ((i % 2 == 0) ? -h : h)
            path.addLine(to: CGPoint(x: x, y: yPos))
        }
    }
    
    private func addVerticalWave(_ path: inout Path, rect: CGRect, x: CGFloat, h: CGFloat) {
        let count = Int(ceil(rect.height / stepWidth)) + 2
        let total = CGFloat(count) * stepWidth
        let startY = rect.midY - total / 2
        
        path.addLine(to: CGPoint(x: x, y: startY))
        
        for i in 1...count {
            let y = startY + CGFloat(i) * stepWidth
            let xPos = x + ((i % 2 == 0) ? -h : h)
            path.addLine(to: CGPoint(x: xPos, y: y))
        }
    }
}

// MARK: - Receipt Dividers

/// Standard 1pt divider line
struct ReceiptDivider: View {
    var color: Color = .secondary
    
    var body: some View {
        color.frame(height: 1)
    }
}

/// Wave divider with zig-zag effect
struct ReceiptWaveDivider: View {
    var body: some View {
        WaveSeparator()
            .stroke(Color.secondary, lineWidth: 1)
            .frame(height: 1)
    }
}

// MARK: - Receipt Header

/// Navigation header with back button and title
struct ReceiptHeader: View {
    let title: String
    var showBackButton: Bool = true
    var scrollOffset: CGFloat = 0
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .center, spacing: AppLayout.spacing) {
            if showBackButton {
                ReceiptIconButton(
                    icon: "arrow_left",
                    showBorder: true,
                    borderOpacity: min(88.8, max(scrollOffset, 0.0)) / 99.9
                ) {
                    onBack?()
                }
            }
            
            Text(title)
                .font(AppFont.displayTitle)
                .lineLimit(1)
                .foregroundStyle(Color.textInk)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: AppLayout.touchTarget)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, AppLayout.spacing)
    }
}

// MARK: - Receipt Section Header

/// Section header with uppercase serif text
struct ReceiptSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .textCase(.uppercase)
            .font(AppFont.sectionHeader)
            .foregroundStyle(Color.textInk)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Receipt Text Field

/// Dashed border text field for inputs
struct ReceiptTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(PlainTextFieldStyle())
            .font(AppFont.monoBody)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .overlay {
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .strokeBorder(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
            }
            .keyboardType(keyboardType)
    }
}

/// Placeholder button styled as text field (for address selection, etc.)
struct ReceiptPlaceholderButton: View {
    let placeholder: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(placeholder)
                .font(AppFont.body)
                .foregroundStyle(Color.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .overlay {
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .strokeBorder(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                }
        }
    }
}

// MARK: - Receipt Item Row

/// Standard product row with image, name, price, and quantity controls
struct ReceiptItemRow: View {
    let imageUrl: String?
    let name: String
    let price: String
    let quantity: Int
    var onIncrease: (() -> Void)? = nil
    var onDecrease: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: AppLayout.spacingMedium) {
            AppRemoteImage(
                url: URL(string: imageUrl ?? ""),
                source: .native,
                contentMode: .fill,
                width: AppLayout.productImageSize,
                height: AppLayout.productImageSize
            )
            
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(AppFont.productTitle)
                    .lineLimit(3)
                    .foregroundStyle(Color.textInk)
                
                Spacer(minLength: AppLayout.spacing)
                
                HStack(spacing: 0) {
                    Text(price)
                        .font(AppFont.monoBody)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(Color.primaryEspresso)
                    
                    Spacer(minLength: 0)
                    
                    // Quantity Controls
                    if let onDecrease = onDecrease, let onIncrease = onIncrease {
                        ReceiptQuantityStepper(
                            quantity: quantity,
                            onDecrease: onDecrease,
                            onIncrease: onIncrease
                        )
                    }
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Quantity Stepper

/// Plus/Minus quantity control matching CheckoutView behavior
struct ReceiptQuantityStepper: View {
    let quantity: Int
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    
    var body: some View {
        AppQuantityStepper(quantity: quantity, onDecrease: onDecrease, onIncrease: onIncrease)
    }
}

// MARK: - Total Bar

/// Fixed bottom bar with total and CTA button
struct ReceiptTotalBar: View {
    let totalLabel: String
    let totalValue: String
    let ctaTitle: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            HStack(spacing: 0) {
                Text(totalLabel)
                    .font(AppFont.totalLabel)
                    .lineLimit(1)
                    .foregroundStyle(Color.textInk)
                
                Spacer(minLength: AppLayout.spacing)
                
                Text(totalValue)
                    .font(AppFont.monoTitle)
                    .foregroundStyle(Color.textInk)
            }
            
            ReceiptPrimaryButton(
                title: ctaTitle,
                isLoading: isLoading,
                isDisabled: isDisabled,
                action: action
            )
        }
        .padding(.vertical, 24)
        .frame(minHeight: AppLayout.touchTarget)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppLayout.spacing)
        .background(Color.backgroundPaper, ignoresSafeAreaEdges: .all)
        .background {
            WaveRect(stepWidth: AppLayout.waveStepWidth, waveEdge: .top)
                .fill(Color.backgroundPaper)
                .offset(y: -AppLayout.halfUnit)
        }
        .overlay(alignment: .top) {
            WaveSeparator(stepWidth: AppLayout.waveStepWidth)
                .stroke(Color.secondary, lineWidth: 1)
                .frame(height: 1)
                .offset(y: -AppLayout.halfUnit)
        }
    }
}

// MARK: - Image Placeholder

struct ReceiptImagePlaceholder: View {
    var size: CGFloat = AppLayout.productImageSize
    
    var body: some View {
        Rectangle()
            .fill(BaseViewColor.placeholder)
            .frame(width: size, height: size)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay {
                Image("photo")
                    .font(AppFont.productTitle)
                    .foregroundStyle(Color.textPrimary.opacity(0.72))
            }
    }
}

// MARK: - Loading Log

/// Receipt-style loading indicator
struct ReceiptLoadingLog: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<5, id: \.self) { i in
                Text("> Loading \(i + 1)...")
                    .font(AppFont.uiMicro)
                    .foregroundStyle(Color.primaryEspresso)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.spacing)
        .background(Color.backgroundPaper)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .strokeBorder(Color.primaryEspresso, lineWidth: 1)
        )
    }
}

// MARK: - Voucher Card (With Image Support)

// MARK: - Ghost preview card (shown when user has no vouchers)

private let ghostColors: [[Color]] = [
    [Color(red: 0.290, green: 0.376, blue: 0.698), Color(red: 0.16, green: 0.24, blue: 0.56)],
    [Color(red: 0.18,  green: 0.52,  blue: 0.36),  Color(red: 0.07, green: 0.34, blue: 0.24)],
    [Color(red: 0.82,  green: 0.45,  blue: 0.18),  Color(red: 0.63, green: 0.27, blue: 0.06)],
]

struct VoucherCardGhost: View {
    let index: Int
    private var colors: [Color] { ghostColors[index % ghostColors.count] }

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                colors[0]
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(.white.opacity(0.22))
            }
            .frame(width: 116)

            VStack(alignment: .leading, spacing: 0) {
                Text("VOUCHER")
                    .font(.custom("GeologicaThinRoman-Medium", size: 18))
                    .foregroundStyle(Color.textPrimary)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 12)
                    .padding(.top, 6)
                Spacer()
                Divider().padding(.bottom, 6)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.25)).frame(width: 30, height: 9)
                        RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.25)).frame(width: 60, height: 9)
                    }
                    Spacer()
                    Text("DÙNG")
                        .font(AppFont.uiMicro)
                        .fontWeight(.semibold)
                        .kerning(2)
                        .underline()
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .padding(.leading, 13)
            .padding(.trailing, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .frame(height: 116)
        .overlay(Rectangle().strokeBorder(Color(UIColor.separator), lineWidth: 0.5))
    }
}

// MARK: - Wallet-style Voucher Pass Card

struct VoucherCard: View {
    let voucher: Voucher
    var showApplyButton: Bool = true
    let action: () -> Void

    private var leftColor: Color {
        switch voucher.discountType {
        case .percentage:    return Color(red: 0.290, green: 0.376, blue: 0.698) // #4A60B2
        case .fixed, .discount: return Color(red: 0.18, green: 0.52, blue: 0.36)
        case .freeDelivery:  return Color(red: 0.82, green: 0.45, blue: 0.18)
        }
    }

    var body: some View {
        AppVoucherPassCard(
            title: "VOUCHER",
            value: voucher.displayValue,
            subtitle: voucher.validUntil.map { "HSD: \($0.formatted(.dateTime.day().month(.twoDigits).year(.defaultDigits)))" } ?? String(localized: "voucher_no_expiry"),
            accentColor: leftColor,
            actionTitle: showApplyButton ? String(localized: "voucher_use_cta") : nil,
            isMuted: !showApplyButton,
            action: showApplyButton ? action : nil
        )
    }
}
