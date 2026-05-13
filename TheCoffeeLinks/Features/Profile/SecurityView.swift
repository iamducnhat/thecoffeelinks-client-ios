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
                ProfileNavigationHeader(title: String(localized: "action_security")) {
                    dismiss()
                }
                
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
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
