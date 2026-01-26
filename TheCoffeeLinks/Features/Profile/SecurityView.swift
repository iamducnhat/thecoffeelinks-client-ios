//
//  SecurityView.swift
//  thecoffeelinks-client-ios
//
//  Created for Profile Feature
//

import SwiftUI

struct SecurityView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var biometricsEnabled = true
    @State private var twoFactorEnabled = false
    
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
                    
                    Text(String(localized: "action_security"))
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
                        
                        // Password Section
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            ProfileSectionHeader(title: "Password")
                            
                            ProfileRow(title: "Change Password", icon: "key", action: {})
                        }
                        
                        // Biometrics Section
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            ProfileSectionHeader(title: "Authentication")
                            
                            ToggleRow(title: "Face ID / Touch ID", icon: "faceid", isOn: $biometricsEnabled)
                            ToggleRow(title: "Two-Factor Auth", icon: "shield.checklist", isOn: $twoFactorEnabled)
                        }
                        
                        // Devices Section
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            ProfileSectionHeader(title: "Devices")
                            
                            ProfileRow(title: "Manage Devices", icon: "iphone", action: {})
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}
