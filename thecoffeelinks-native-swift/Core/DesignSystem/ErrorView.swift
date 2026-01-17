//
//  ErrorView.swift
//  thecoffeelinks-native-swift
//
//  Magazine/Notion-style editorial redesign
//

import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: Editorial.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.red)
            
            VStack(spacing: Editorial.Spacing.xs) {
                Text(title)
                    .font(Editorial.heading())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Editorial.Colors.textPrimary)
                
                Text(message)
                    .font(Editorial.body())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Editorial.Colors.textSecondary)
            }
            
            if let retry = retryAction {
                Button(action: retry) {
                    Text("Try Again")
                        .font(Editorial.body())
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Editorial.Spacing.lg)
                        .padding(.vertical, Editorial.Spacing.sm)
                        .background(Editorial.Colors.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Editorial.Spacing.lg)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(Editorial.Spacing.md)
    }
}
