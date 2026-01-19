//
//  CartMonitor.swift
//  thecoffeelinks-native-swift
//
//  Created for: Global Floating Cart
//

import SwiftUI

struct CartMonitor: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var showCheckout = false
    
    // iOS 26/Modern Floating Style
    // Using a clear material background or floating pill
    
    var body: some View {
        Button {
            showCheckout = true
        } label: {
            HStack(spacing: AppLayout.spacingSmall) {
                Text("\(cartViewModel.itemCount) item\(cartViewModel.itemCount == 1 ? "" : "s")")
                    .font(AppFont.body)
                
                Spacer()
                
                Text(cartViewModel.total.formattedCurrency)
                    .font(AppFont.monoBody.bold())
            }
            .foregroundColor(Color.textInk)
            //.padding(.vertical, 8)
            .padding(.horizontal, AppLayout.spacing)
        }
        .fullScreenCover(isPresented: $showCheckout) {
            CheckoutView()
        }
    }
}
