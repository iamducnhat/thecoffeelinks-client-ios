//
//  VoucherRedemptionSheet.swift
//  thecoffeelinks-native-swift
//
//  Redesigned for fast redemption utility.
//  Minimal UI, prominent QR, copyable code.
//

import SwiftUI
import UniformTypeIdentifiers

struct VoucherRedemptionSheet: View {
    let voucher: Voucher
    @Environment(\.dismiss) private var dismiss
    @State private var hasCopied = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Top Bar
                HStack {
                    Spacer()
                    
                    Text("Redeem Voucher")
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textInk)
                            .frame(width: 44, height: 44)
                            .background(Color.backgroundPaper)
                            .clipShape(Circle())
                    }
                }
                .padding(AppLayout.spacing)
                .overlay(alignment: .bottom) {
                    Color.secondary.frame(height: 1)
                }
                
                ScrollView {
                    VStack(spacing: AppLayout.spacingXL) {
                        
                        // 2. Discount Display
                        VStack(spacing: 4) {
                            Text(voucher.displayValue) // e.g. "50% OFF"
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.primaryEspresso)
                            
                            // Subtitle logic (using description or generic fallback)
                            Text(voucher.description ?? "Scan to redeem")
                                .font(AppFont.body)
                                .foregroundStyle(Color.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, AppLayout.spacingXL)
                        
                        // 3. QR Code (Centered, Large)
                        QRRenderView(payload: voucher.code)
                            .frame(width: 280, height: 280) // Larger size
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                        
                        // 4. Voucher Code Section
                        VStack(spacing: AppLayout.spacingSmall) {
                            Text("VOUCHER CODE")
                                .font(AppFont.uiMicro)
                                .textCase(.uppercase)
                                .foregroundStyle(Color.textMuted)
                                .tracking(1)
                            
                            HStack(spacing: AppLayout.spacingMedium) {
                                Text(voucher.code)
                                    .font(.system(.title3, design: .monospaced, weight: .bold))
                                    .foregroundStyle(Color.textInk)
                                    .tracking(2)
                                
                                Button {
                                    UIPasteboard.general.setValue(voucher.code, forPasteboardType: UTType.plainText.identifier)
                                    withAnimation {
                                        hasCopied = true
                                    }
                                    
                                    // Reset copy state after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            hasCopied = false
                                        }
                                    }
                                } label: {
                                    if hasCopied {
                                        Label("Copied", systemImage: "checkmark")
                                            .font(AppFont.uiCaption)
                                            .foregroundStyle(Color.semanticSuccess)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.semanticSuccess.opacity(0.1))
                                            .clipShape(Capsule())
                                    } else {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 18))
                                            .foregroundStyle(Color.primaryEspresso)
                                            .frame(width: 44, height: 44)
                                            .background(Color.primaryEspresso.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .background(Color.surfaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border.opacity(0.5), lineWidth: 1)
                            )
                        }
                        
                        // 5. Metadata
                        VStack(spacing: AppLayout.spacing) {
                            HStack(spacing: 32) {
                                if let validUntil = voucher.validUntil {
                                    metadataItem(label: "EXPIRES", value: validUntil.formatted(date: .abbreviated, time: .omitted))
                                }
                                
                                // Usage limit fallback since it's commonly 1
                                metadataItem(label: "USAGE", value: (voucher.usageLimit == 1) ? "One-time" : "Unlimited")
                            }
                        }
                        .padding(.top, AppLayout.spacing)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
    
    // Helper for metadata
    private func metadataItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(AppFont.uiMicro)
                .foregroundStyle(Color.textMuted)
                .tracking(0.5)
            
            Text(value)
                .font(AppFont.uiCaption)
                .foregroundStyle(Color.textInk)
        }
    }
}
