//
//  ErrorView.swift
//  thecoffeelinks-client-ios
//
//  Magazine/Notion-style editorial redesign
//

import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: BaseViewLayout.spacingMedium) {
            Image("exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.red)
            
            VStack(spacing: BaseViewLayout.spacingSmall) {
                Text(title)
                    .font(BaseViewFont.sectionHeader)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BaseViewColor.textPrimary)
                
                Text(message)
                    .font(BaseViewFont.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BaseViewColor.textSecondary)
            }
            
            if let retry = retryAction {
                Button(action: retry) {
                    Text("Try Again")
                        .font(BaseViewFont.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, BaseViewLayout.spacing)
                        .padding(.vertical, BaseViewLayout.spacingCompact)
                        .background(BaseViewColor.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(BaseViewLayout.spacing)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(BaseViewLayout.spacingMedium)
    }
}
