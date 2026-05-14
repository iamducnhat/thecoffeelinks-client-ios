//
//  CartMonitor.swift
//  thecoffeelinks-client-ios
//
//  Created for: Global Floating Cart
//

import SwiftUI

struct CartMonitor: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cartViewModel: CartViewModel
    
    // iOS 26/Modern Floating Style
    // Using a clear material background or floating pill
    
    var body: some View {
        Button {
            appState.showCheckout = true
        } label: {
            HStack(spacing: BaseViewLayout.spacingSmall) {
                Text("common_item_count_format \(cartViewModel.itemCount)")
                    .font(BaseViewFont.body)
                
                Spacer()
                
                Text(cartViewModel.total.formattedVND)
                    .font(BaseViewFont.monoBody.bold())
            }
            .foregroundColor(BaseViewColor.textPrimary)
            //.padding(.vertical, 8)
            .padding(.horizontal, BaseViewLayout.spacing)
        }
    }
}
