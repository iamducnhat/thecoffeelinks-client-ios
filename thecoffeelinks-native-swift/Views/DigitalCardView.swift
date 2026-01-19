//
//  DigitalCardView.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design / Boarding Pass Style
//  Aligned with design goals: Calm, authoritative, editorial.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct DigitalCardView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            // Main Content
            ScrollView {
                DigitalCredentialContent()
                    .padding(AppLayout.spacing)
            }
            .scrollIndicators(.hidden)
            
            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textMuted)
                            .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                    }
                }
                .padding(.horizontal, AppLayout.spacing)
                Spacer()
            }
        }
    }
}

// MARK: - Reusable Content View

struct DigitalCredentialContent: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    // QR Manager responsible for fetching signed payload
    @StateObject private var qrManager = QRPayloadManager()
    
    // Selection state for vouchers
    @State private var selectedVoucher: UserVoucher? = nil
    
    var body: some View {
        VStack(spacing: AppLayout.spacingXL) {
            
            // 1. Context Header
            VStack(spacing: 4) {
                Text("THE COFFEE LINKS")
                    .font(AppFont.sectionHeader)
                    .foregroundColor(Color.textInk)
                
                Text("DIGITAL CREDENTIAL")
                    .font(AppFont.uiMicro)
                    .textCase(.uppercase)
                    .kerning(1.5)
                    .foregroundColor(Color.textMuted)
            }
            .padding(.top, AppLayout.spacingLarge)
            
            // 2. QR Code & State
            VStack(spacing: AppLayout.spacing) {
                // QR
                QRCodeView(string: qrManager.currentPayload ?? "loading")
                    .frame(width: 240, height: 240)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                    .padding(AppLayout.spacing)
                    .background(Color.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                    .opacity(qrManager.currentPayload == nil ? 0.3 : 1.0)
                    .overlay {
                        if qrManager.isLoading && qrManager.currentPayload == nil {
                            ProgressView()
                        }
                    }
                
                // State Indicator
                Text(qrStateText)
                    .font(AppFont.uiCaption)
                    .foregroundColor(selectedVoucher != nil ? Color.primaryEspresso : Color.textMuted)
                    .animation(.easeInOut, value: selectedVoucher)
                    .id(selectedVoucher?.id ?? "none") // Force redraw for animation clarity
            }
            
            // 3. Identity Block
            VStack(spacing: 4) {
                Text(authViewModel.currentUser?.displayName ?? "Member")
                    .font(AppFont.displayTitle)
                    .foregroundColor(Color.textInk)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 8) {
                    Text(authViewModel.currentUser?.membershipTier.displayName ?? "Bronze")
                    Text("·")
                    Text(authViewModel.currentUser?.shortId ?? "******")
                        .font(AppFont.monoBody)
                }
                .font(AppFont.body)
                .foregroundColor(Color.primaryEspresso)
            }
            
            DividerLine()
            
            // 4. Voucher Section (Conditional)
            if !profileViewModel.userVouchers.isEmpty {
                VStack(alignment: .leading, spacing: AppLayout.spacing) {
                    Text("AVAILABLE VOUCHERS")
                        .font(AppFont.uiMicro)
                        .textCase(.uppercase)
                        .kerning(1.5)
                        .foregroundColor(Color.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    ForEach(profileViewModel.userVouchers.prefix(5)) { uv in // Limit listed
                        if uv.status == .active {
                            VoucherRow(userVoucher: uv, isSelected: selectedVoucher?.id == uv.id)
                                .onTapGesture {
                                    withAnimation {
                                        if selectedVoucher?.id == uv.id {
                                            selectedVoucher = nil // Deselect
                                        } else {
                                            selectedVoucher = uv
                                        }
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, AppLayout.spacingLarge)
                
                DividerLine()
            }
            
            // 5. Stats Section
            VStack(spacing: AppLayout.spacing) {
                StatRow(label: "POINTS", value: "\(authViewModel.currentUser?.points ?? 0)")
                StatRow(label: "VOUCHERS", value: "\(profileViewModel.userVouchers.filter { $0.status == .active }.count)")
                StatRow(label: "ORDERS", value: "\(profileViewModel.orderCount)")
            }
            .padding(.horizontal, AppLayout.spacingLarge)
            
            DividerLine()
            
            // 6. Actions
            HStack(spacing: AppLayout.spacingXL) {
                ActionButton(icon: "doc.on.doc", title: "Copy ID") {
                    if let mid = authViewModel.currentUser?.shortId {
                        UIPasteboard.general.string = mid
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                }
                
                ActionButton(icon: "arrow.clockwise", title: "Refresh") {
                    profileViewModel.loadProfile()
                    qrManager.refreshQR()
                }
            }
            .padding(.bottom, AppLayout.spacingXL)
        }
        .onAppear {
            qrManager.startRotation()
            // Ensure we have vouchers
            profileViewModel.loadProfile()
        }
        .onDisappear {
            qrManager.stopRotation()
        }
        .onChange(of: selectedVoucher?.id) { newValue in
            // Update QR Manager with selected voucher instance ID (UserVoucher.id)
            qrManager.selectVoucher(newValue)
        }
    }
    
    private var qrStateText: String {
        if let voucher = selectedVoucher?.voucher {
            return "Redeem: \(voucher.code)"
        } else {
            return "Member Verification"
        }
    }
}

// MARK: - Components

struct VoucherRow: View {
    let userVoucher: UserVoucher
    let isSelected: Bool
    
    var body: some View {
        HStack {
            // Checkbox style indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? Color.primaryEspresso : Color.textMuted)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(userVoucher.voucher?.description ?? userVoucher.voucher?.code ?? "Voucher")
                    .font(AppFont.body)
                    .foregroundColor(Color.textInk)
                
                if let expiry = userVoucher.voucher?.validUntil {
                    Text("Expires \(expiry.formatted(date: .abbreviated, time: .omitted))")
                        .font(AppFont.uiCaption)
                        .foregroundColor(Color.textMuted)
                }
            }
            
            Spacer()
            
            if let value = userVoucher.voucher {
                Text(value.displayValue)
                    .font(AppFont.monoBody)
                    .foregroundColor(Color.primaryEspresso)
            }
        }
        .padding(AppLayout.spacing)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .strokeBorder(isSelected ? Color.primaryEspresso : Color.textMuted.opacity(0.2), lineWidth: 1)
                .background(isSelected ? Color.primaryEspresso.opacity(0.05) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.textMuted.opacity(0.2))
            .frame(height: 1)
            .padding(.horizontal, AppLayout.spacingLarge)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFont.sectionHeader) // Serif
                .foregroundColor(Color.textInk)
                .font(.system(size: 14))
            
            Spacer()
            
            Text(value)
                .font(AppFont.monoHeadline) // Monospaced for values
                .foregroundColor(Color.textInk)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(AppFont.uiButton)
            .foregroundColor(Color.primaryEspresso)
        }
    }
}

struct QRCodeView: View {
    let string: String
    
    var body: some View {
        if let uiImage = generateQRCode(from: string) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
        } else {
            Rectangle()
                .fill(Color.surfaceCard)
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H" // High for better scanning
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
