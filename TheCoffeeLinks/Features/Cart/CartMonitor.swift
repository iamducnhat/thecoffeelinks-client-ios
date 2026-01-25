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
            HStack(spacing: AppLayout.spacingSmall) {
                Text("common_item_count_format \(cartViewModel.itemCount)")
                    .font(AppFont.body)
                
                Spacer()
                
                Text(cartViewModel.total.formattedVND)
                    .font(AppFont.monoBody.bold())
            }
            .foregroundColor(Color.textInk)
            //.padding(.vertical, 8)
            .padding(.horizontal, AppLayout.spacing)
        }
    }
}
