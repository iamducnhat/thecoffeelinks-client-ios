//
//  NotificationsView.swift
//  thecoffeelinks-client-ios
//
//  Created for Profile Feature
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var pushEnabled = true
    @State private var emailEnabled = true
    @State private var smsEnabled = false
    @State private var promoEnabled = true
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(BaseViewColor.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "action_notifications"))
                        .font(BaseViewFont.sectionTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding(.horizontal, BaseViewLayout.screenInset)
                .padding(.top, BaseViewLayout.screenTopInset)
                .padding(.bottom, BaseViewLayout.screenInset)
                
                Rectangle()
                    .fill(BaseViewColor.border)
                    .frame(height: BaseViewLayout.cardBorderWidth)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: BaseViewLayout.majorSectionGap) {
                        
                        VStack(alignment: .leading, spacing: BaseViewLayout.cardGap) {
                            Text("Channels")
                                .font(BaseViewFont.labelStrong)
                                .textCase(.uppercase)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            ToggleRow(title: "Push Notifications", icon: "bell", isOn: $pushEnabled)
                            ToggleRow(title: "Email", icon: "envelope", isOn: $emailEnabled)
                            ToggleRow(title: "SMS", icon: "message", isOn: $smsEnabled)
                        }
                        
                        VStack(alignment: .leading, spacing: BaseViewLayout.cardGap) {
                            Text("Preferences")
                                .font(BaseViewFont.labelStrong)
                                .textCase(.uppercase)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            ToggleRow(title: "Promotions & Offers", icon: "tag", isOn: $promoEnabled)
                        }
                    }
                    .padding(.horizontal, BaseViewLayout.screenInset)
                    .padding(.top, BaseViewLayout.sectionGap)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}
