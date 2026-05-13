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
                ProfileNavigationHeader(title: String(localized: "action_notifications")) {
                    dismiss()
                }
                
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
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
