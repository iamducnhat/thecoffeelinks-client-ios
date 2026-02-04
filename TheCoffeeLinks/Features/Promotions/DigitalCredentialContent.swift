import SwiftUI

struct DigitalCredentialContent: View {
    let memberId: String
    let userName: String
    let tier: String
    let points: Int
    let vouchersCount: Int
    let ordersCount: Int
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: AppLayout.spacing) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(AppFont.sectionHeader)
                        .foregroundColor(Color.textPrimary)
                    Text(tier)
                        .font(AppFont.uiCaption)
                        .foregroundColor(Color.textSecondary)
                }
                Spacer()
                // Refresh Button
                Button(action: onRefresh) {
                    Image("rotate_cw")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            Divider().padding(.horizontal, -AppLayout.spacing)
            
            // QR Code Section
            // Payload format: u:<shortUserId>
            // We use the memberId (shortId) directly
            VStack(spacing: 8) {
                QRRenderView(payload: "u:\(memberId)")
                    .frame(width: 180, height: 180, alignment: .center)
                    .padding(AppLayout.spacing)
                    .background(Color.white)
                    .cornerRadius(AppRadius.small)
                
                Text(memberId)
                    .font(AppFont.monoHeadline)
                    .tracking(2)
                    .foregroundColor(Color.textPrimary)
            }
            .padding(.vertical, AppLayout.spacing)
            
            Divider().padding(.horizontal, -AppLayout.spacing)
            
            // Stats Row
            HStack(spacing: 0) {
                statItem(value: "\(points)", label: "Points")
                Spacer()
                statItem(value: "\(vouchersCount)", label: "Vouchers")
                Spacer()
                statItem(value: "\(ordersCount)", label: "Orders")
            }
        }
        .padding(AppLayout.spacing)
        .background(Color.surfacePrimary)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFont.monoHeadline)
                .foregroundColor(Color.textPrimary)
            Text(label)
                .font(AppFont.uiCaption)
                .foregroundColor(Color.textSecondary)
        }
    }
}
