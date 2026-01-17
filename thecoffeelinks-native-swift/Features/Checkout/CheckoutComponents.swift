//
//  CheckoutComponents.swift
//  thecoffeelinks-native-swift
//
//  Retro-Editorial Design
//  Components for Checkout Flow
//

import SwiftUI

// MARK: - Undo Countdown
struct UndoCountdownView: View {
    let duration: TimeInterval = 30
    @State private var timeRemaining: TimeInterval = 30
    @State private var timer: Timer?
    let onCancel: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
             Text("Order Placed")
                .fontH2()
                .foregroundColor(.primaryEspresso)
            
            ZStack {
                Circle()
                    .stroke(Color.border, lineWidth: 2)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining / duration))
                    .stroke(Color.primaryEspresso, style: StrokeStyle(lineWidth: 2, lineCap: .square))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                
                Text("\(Int(timeRemaining))")
                    .fontBody()
                    .fontWeight(.bold)
                    .foregroundColor(.textInk)
            }
            
            Text("You can undo this order within 30s")
                .fontCaption()
                .foregroundColor(.textMuted)
            
            Button("Undo Order") {
                timer?.invalidate()
                onCancel()
            }
            .fontButton()
            .foregroundColor(.semanticError)
            .padding(.top, 8)
        }
        .padding(32)
        .background(Color.surfaceCard)
        .cornerRadius(0) // Sharp
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                onComplete()
            }
        }
    }
}

// MARK: - Store Picker (Full Sheet)
struct StorePickerSheet: View {
    @EnvironmentObject var storeViewModel: StoreViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPaper.ignoresSafeArea()
                
                List(storeViewModel.stores) { store in
                     Button(action: {
                         storeViewModel.selectStore(store)
                         isPresented = false
                     }) {
                         HStack {
                             VStack(alignment: .leading, spacing: 4) {
                                 Text(store.name)
                                     .fontBody()
                                     .foregroundColor(.textInk)
                                 Text(store.address)
                                     .fontCaption()
                                     .foregroundColor(.textMuted)
                             }
                             Spacer()
                             if storeViewModel.selectedStore?.id == store.id {
                                 Image(systemName: "checkmark")
                                     .foregroundColor(.primaryEspresso)
                             }
                         }
                         .padding(.vertical, 8)
                     }
                     .listRowBackground(Color.surfaceCard)
                 }
                 .listStyle(.plain)
            }
            .navigationTitle("Select Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.textInk)
                }
            }
        }
    }
}
