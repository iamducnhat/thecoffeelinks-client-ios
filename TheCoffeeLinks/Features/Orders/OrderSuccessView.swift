//
//  OrderSuccessView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct OrderSuccessView: View {
    let onDismiss: () -> Void
    
    @State private var lines: [String] = []
    @State private var showDone = false
    
    let terminalOutput = [
        "> Submitting order...",
        "> Securing payment...",
        "> Order confirmed",
        "> Notification sent",
        "> Processing...",
        "> Order placed successfully",
        "─────────────────────────",
        "✓ Enjoy your coffee!"
    ]
    
    var body: some View {
        ZStack {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                Spacer()
                
                // Terminal output simulation
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(AppFont.monoBody)
                        .foregroundStyle(line.contains("successfully") || line.contains("✓") ? Color.primaryEspresso : Color.textInk)
                }
                
                if showDone {
                    VStack(alignment: .leading, spacing: AppLayout.spacingXL) {
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text(String(localized: "order_success_title"))
                                .font(AppFont.displayTitle)
                                .foregroundStyle(Color.textInk)
                            
                            Text(String(localized: "order_success_message"))
                                .font(AppFont.body)
                                .foregroundStyle(Color.textMuted)
                        }
                        .padding(.top, AppLayout.spacingXL)
                        
                        Button {
                            onDismiss()
                        } label: {
                            Text(String(localized: "common_done"))
                                .font(AppFont.monoCTA)
                                .foregroundStyle(Color.backgroundPaper)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        }
                    }
                    .transition(.opacity)
                }
                
                Spacer()
            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            DependencyContainer.shared.hapticManager.playSuccess()
            simulateTerminal()
        }
    }
    
    private func simulateTerminal() {
        for (index, line) in terminalOutput.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                withAnimation {
                    lines.append(line)
                }
                
                if index == terminalOutput.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showDone = true
                        }
                    }
                }
            }
        }
    }
}
