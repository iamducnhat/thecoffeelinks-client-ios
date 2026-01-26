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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image("chevron.left")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textInk)
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "action_notifications"))
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Image("chevron.left").opacity(0)
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
                                .foregroundStyle(Color.textInk)
                            
                            ToggleRow(title: "Push Notifications", icon: "bell", isOn: $pushEnabled)
                            ToggleRow(title: "Email", icon: "envelope", isOn: $emailEnabled)
                            ToggleRow(title: "SMS", icon: "message", isOn: $smsEnabled)
                        }
                        
                        // Types
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Preferences")
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            ToggleRow(title: "Promotions & Offers", icon: "tag", isOn: $promoEnabled)
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}
