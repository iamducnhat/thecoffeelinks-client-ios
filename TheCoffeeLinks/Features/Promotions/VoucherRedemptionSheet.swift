//
//  VoucherRedemptionSheet.swift
//  thecoffeelinks-client-ios
//
//  Redesigned for fast redemption utility.
//  Minimal UI, prominent barcode, copyable code.
//

import SwiftUI
import UniformTypeIdentifiers

struct VoucherRedemptionSheet: View {
    let voucher: Voucher
    @Environment(\.dismiss) private var dismiss
    
    @State private var hasCopied = false
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Top Bar
                HStack {
                    Spacer()
                    
                    Text(String(localized: "voucher_redeem_title"))
                        .font(BaseViewFont.sectionTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(BaseViewFont.body)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(BaseViewColor.background)
                            .clipShape(Circle())
                    }
                }
                .padding(BaseViewLayout.spacing)
                .overlay(alignment: .bottom) {
                    Color.secondary.frame(height: 1)
                }
                
                ScrollView {
                    VStack(spacing: BaseViewLayout.spacingXL) {
                        
                        // 2. Discount Display
                        VStack(spacing: 4) {
                            Text(voucher.displayValue) // e.g. "50% OFF"
                                .font(BaseViewFont.screenTitle)
                                .foregroundStyle(BaseViewColor.accent)
                            
                            // Subtitle logic (using description or generic fallback)
                            Text(voucher.description ?? "Scan to redeem")
                                .font(BaseViewFont.body)
                                .foregroundStyle(BaseViewColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, BaseViewLayout.spacingXL)
                        
                        // 3. Barcode (Centered, Large)
                        ZStack {
                            // Use only first 8 chars of UUID for an ultra-short barcode
                            BarcodeRenderView(payload: String(voucher.id.prefix(8)).uppercased())
                                .frame(width: 320, height: 80)
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusLarge, style: .continuous))
                        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: BaseViewLayout.radiusLarge, style: .continuous)
                                .strokeBorder(BaseViewColor.border.opacity(0.5), lineWidth: 1)
                        )
                        
                        // 4. Voucher Code (Copyable)
                        VStack(spacing: BaseViewLayout.spacingSmall) {
                            Text(String(localized: "voucher_code_label"))
                                .font(BaseViewFont.label)
                                .textCase(.uppercase)
                                .foregroundStyle(BaseViewColor.textSecondary)
                            
                            HStack(spacing: 12) {
                                Text(voucher.code)
                                    .font(.system(.title2, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundStyle(BaseViewColor.accent)
                                
                                Button {
                                    UIPasteboard.general.string = voucher.code
                                    withAnimation(.spring()) {
                                        hasCopied = true
                                    }
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    
                                    // Reset after 2s
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            hasCopied = false
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(hasCopied ? "circle_check" : "doc.on.doc")
                                        if hasCopied {
                                            Text(String(localized: "common_copied"))
                                                .font(BaseViewFont.label)
                                        }
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(hasCopied ? .green : BaseViewColor.accent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(hasCopied ? Color.green.opacity(0.1) : BaseViewColor.accent.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        
                        // 5. Metadata Grid
                        VStack(spacing: BaseViewLayout.spacing) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                if let validUntil = voucher.validUntil {
                                    metadataItem(label: "EXPIRES", value: validUntil.formatted(date: .abbreviated, time: .omitted))
                                }
                                
                                // Enhanced Usage logic
                                let remaining = max(0, voucher.maxUsesPerUser - voucher.userUsesCount)
                                let usageValue = voucher.maxUsesPerUser > 1 
                                    ? "\(remaining) of \(voucher.maxUsesPerUser) left" 
                                    : "One-time"
                                
                                metadataItem(label: "USAGE", value: usageValue)
                                
                                if let minOrder = voucher.minOrderAmount, minOrder > 0 {
                                    metadataItem(label: "MIN ORDER", value: minOrder.formattedVND)
                                }
                                
                                if let maxDiscount = voucher.maxDiscount, maxDiscount > 0 {
                                    metadataItem(label: "MAX SAVING", value: maxDiscount.formattedVND)
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                        .padding(.top, BaseViewLayout.spacing)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(BaseViewLayout.spacing)
                }
            }
        }
    }
    
    // Helper for metadata
    private func metadataItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(BaseViewFont.label)
                .foregroundStyle(BaseViewColor.textSecondary)
                .tracking(0.5)
            
            Text(value)
                .font(BaseViewFont.labelStrong)
                .foregroundStyle(BaseViewColor.textPrimary)
        }
    }
}

