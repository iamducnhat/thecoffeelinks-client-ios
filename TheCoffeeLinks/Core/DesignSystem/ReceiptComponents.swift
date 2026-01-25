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
    var stepWidth: CGFloat = AppLayout.waveStepWidth
    
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
    var stepWidth: CGFloat = AppLayout.waveStepWidth
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
                    icon: "arrow.left",
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
                    .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
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
                        .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
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
            // Image Placeholder
            AsyncImage(url: URL(string: imageUrl ?? "")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.textInk.opacity(0.1))
                        .overlay {
                            Image(systemName: "photo")
                                .font(AppFont.productTitle)
                                .foregroundStyle(Color.textInk)
                        }
                }
            }
            .frame(width: AppLayout.productImageSize, height: AppLayout.productImageSize)
            .cornerRadius(AppLayout.cornerRadius)
            
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
        HStack(spacing: AppLayout.spacingSmall) {
            ReceiptStepperButton(
                icon: "minus",
                isDisabled: quantity <= 1,
                action: onDecrease
            )
            
            Text("\(quantity)")
                .font(AppFont.monoHeadline)
                .frame(minWidth: AppLayout.quantityMinWidth)
            
            ReceiptStepperButton(
                icon: "plus",
                action: onIncrease
            )
        }
        .fixedSize()
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
            .fill(Color.textInk.opacity(0.1))
            .frame(width: size, height: size)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay {
                Image(systemName: "photo")
                    .font(AppFont.productTitle)
                    .foregroundStyle(Color.textInk)
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
                .stroke(Color.primaryEspresso, lineWidth: 1)
        )
    }
}

// MARK: - Voucher Card (With Image Support)

struct VoucherCard: View {
    let voucher: Voucher
    var showApplyButton: Bool = true
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Full-width image banner (16:9 aspect ratio)
            if let imageUrl = voucher.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        // Error placeholder
                        voucherImagePlaceholder
                    } else {
                        // Loading placeholder
                        voucherImagePlaceholder
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(16/9, contentMode: .fit)
                .clipped()
            } else {
                // No image URL - show colored placeholder
                voucherImagePlaceholder
                    .aspectRatio(16/9, contentMode: .fit)
            }
            
            Color.secondary.frame(height: 1)
            
            // Voucher details
            VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(voucher.displayTitle)
                            .font(AppFont.headline)
                            .foregroundStyle(Color.textInk)
                        if let description = voucher.description {
                            Text(description)
                                .font(AppFont.uiCaption)
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                    Spacer()
                    Text(voucher.displayValue)
                        .font(AppFont.monoBody.bold())
                        .foregroundStyle(Color.primaryEspresso)
                }
                
                Color.secondary.frame(height: 1)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Code: \(voucher.code)")
                            .font(AppFont.uiMicro)
                        if let validUntil = voucher.validUntil {
                            Text("Valid until: \(validUntil.formatted(.dateTime.month().day().year()))")
                                .font(AppFont.uiMicro)
                        } else {
                            Text("No expiration")
                                .font(AppFont.uiMicro)
                        }
                    }
                    .foregroundStyle(Color.textMuted)
                    
                    Spacer()
                    
                    if showApplyButton {
                        Button(action: action) {
                            Text("Apply")
                                .font(AppFont.monoBody)
                                .foregroundStyle(Color.backgroundPaper)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.primaryEspresso)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        }
                    } else {
                        Text("Used")
                            .font(AppFont.uiMicro)
                            .foregroundStyle(Color.textMuted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.surfaceCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(AppLayout.spacing)
        }
        .background(Color.backgroundPaper)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
    }
    
    private var voucherImagePlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.primaryEspresso.opacity(0.15),
                        Color.primaryEspresso.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack {
                    Spacer()
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.primaryEspresso.opacity(0.3))
                    Spacer()
                }
            )
    }
}
