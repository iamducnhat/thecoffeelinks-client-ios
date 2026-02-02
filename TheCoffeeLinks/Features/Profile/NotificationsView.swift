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
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "action_notifications"))
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                    .opacity(0.1)
                
                ScrollView {
                    VStack(spacing: AppLayout.spacingXL) {
                        
                        // Channels
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Channels")
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            ToggleRow(title: "Push Notifications", icon: "bell", isOn: $pushEnabled)
                            ToggleRow(title: "Email", icon: "envelope", isOn: $emailEnabled)
                            ToggleRow(title: "SMS", icon: "message", isOn: $smsEnabled)
                        }
                        
                        // Types
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Preferences")
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            ToggleRow(title: "Promotions & Offers", icon: "tag", isOn: $promoEnabled)
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}
