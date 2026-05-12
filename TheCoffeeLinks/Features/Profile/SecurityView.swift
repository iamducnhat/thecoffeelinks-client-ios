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
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(BaseViewColor.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "action_security"))
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
                            ProfileSectionHeader(title: "Password")
                            
                            ProfileRow(title: "Change Password", icon: "key", action: {})
                        }
                        
                        VStack(alignment: .leading, spacing: BaseViewLayout.cardGap) {
                            ProfileSectionHeader(title: "Authentication")
                            
                            ToggleRow(title: "Face ID / Touch ID", icon: "faceid", isOn: $biometricsEnabled)
                            ToggleRow(title: "Two-Factor Auth", icon: "shield.checklist", isOn: $twoFactorEnabled)
                        }
                        
                        VStack(alignment: .leading, spacing: BaseViewLayout.cardGap) {
                            ProfileSectionHeader(title: "Devices")
                            
                            ProfileRow(title: "Manage Devices", icon: "iphone", action: {})
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
