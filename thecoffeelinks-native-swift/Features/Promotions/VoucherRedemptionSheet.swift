//
//  VoucherRedemptionSheet.swift
//  thecoffeelinks-native-swift
//
//  Redesigned for fast redemption utility.
//  Minimal UI, prominent QR, copyable code.
//

import SwiftUI
import UniformTypeIdentifiers

// Response model for signing (internal)
struct SignVoucherResponse: Decodable {
    let signedQr: String
}

struct SignedQRRequest: Encodable {
    let voucherId: String
}

struct VoucherRedemptionSheet: View {
    let voucher: Voucher
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var networkService: NetworkService
    
    @State private var hasCopied = false
    @State private var signedQrCode: String?
    @State private var isLoadingQR = true
    @State private var fetchError: String?
    
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
                                .font(AppFont.displayH1)
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
                        ZStack {
                            if let qrString = signedQrCode {
                                QRRenderView(payload: qrString)
                                    .scaledToFit()
                                    .frame(width: 280, height: 280) // Larger size
                            } else if isLoadingQR {
                                ProgressView()
                                    .frame(width: 280, height: 280)
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(.red)
                                    Text("Failed to load QR")
                                        .font(AppFont.uiCaption)
                                    if let err = fetchError {
                                        Text(err)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                    Button("Retry") {
                                        Task { await fetchSignedQR() }
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .frame(width: 280, height: 280)
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.border.opacity(0.5), lineWidth: 1)
                        )
                        
                        // 4. Warning (Dynamic Code)
                        // We removed the static code display because it's no longer useful for redemption
                        // Only show if we need a fallback, but for security we hide the raw code usually.
                        // However, keeping the "ID" might be useful for support.
                        
                        VStack(spacing: AppLayout.spacingSmall) {
                            Text("SECURITY ID")
                                .font(AppFont.uiMicro)
                                .textCase(.uppercase)
                                .foregroundStyle(Color.textMuted)
                            
                             Text(voucher.id.prefix(8).uppercased())
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(Color.textMuted)
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
        .task {
            await fetchSignedQR()
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
    
    private func fetchSignedQR() async {
        isLoadingQR = true
        fetchError = nil
        
        do {
            // Use strict encoder to preserve camelCase "voucherId"
            let strictEncoder = JSONEncoder()
            strictEncoder.keyEncodingStrategy = .useDefaultKeys
            
            let response: SignVoucherResponse = try await networkService.post(
                "/api/vouchers/sign",
                body: SignedQRRequest(voucherId: voucher.id),
                encoder: strictEncoder
            )
            
            withAnimation {
                signedQrCode = response.signedQr
                isLoadingQR = false
            }
        } catch {
            print("QR Fetch Error: \(error.localizedDescription)")
            withAnimation {
                fetchError = "Secure connection failed"
                isLoadingQR = false
            }
        }
    }
}

