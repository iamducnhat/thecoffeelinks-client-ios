//
//  RefillPromptService.swift
//  thecoffeelinks-native-swift
//
//  Tracks user session time and prompts for refill after 90 minutes
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

@MainActor
class RefillPromptService: ObservableObject {
    static let shared = RefillPromptService()
    
    @Published var showRefillPrompt = false
    @Published var sessionStartTime: Date?
    @Published var currentStoreId: String?
    
    private var sessionTimer: Timer?
    private let refillThreshold: TimeInterval = 90 * 60 // 90 minutes
    
    private init() {}
    
    // MARK: - Session Management
    
    func startSession(storeId: String) {
        currentStoreId = storeId
        sessionStartTime = Date()
        
        // Cancel any existing timer
        sessionTimer?.invalidate()
        
        // Set timer for 90 minutes
        sessionTimer = Timer.scheduledTimer(withTimeInterval: refillThreshold, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.triggerRefillPrompt()
            }
        }
        
        print("📍 Session started at store: \(storeId)")
    }
    
    func endSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        sessionStartTime = nil
        currentStoreId = nil
        showRefillPrompt = false
        
        print("📍 Session ended")
    }
    
    var sessionDuration: TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    var sessionDurationFormatted: String {
        let minutes = Int(sessionDuration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMins = minutes % 60
            return "\(hours)h \(remainingMins)m"
        }
    }
    
    // MARK: - Refill Prompt
    
    private func triggerRefillPrompt() {
        showRefillPrompt = true
        
        // Also send local notification if app is in background
        scheduleLocalNotification()
    }
    
    func dismissRefillPrompt() {
        showRefillPrompt = false
    }
    
    func acceptRefillPrompt() {
        showRefillPrompt = false
        // Reset timer for another 90 minutes
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: refillThreshold, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.triggerRefillPrompt()
            }
        }
    }
    
    // MARK: - Local Notifications
    
    private func scheduleLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Need a refill?"
        content.body = "You've been here \(sessionDurationFormatted). Same again?"
        content.sound = .default
        content.categoryIdentifier = "REFILL_PROMPT"
        
        let request = UNNotificationRequest(
            identifier: "refill-\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}

// MARK: - Refill Prompt View

struct RefillPromptView: View {
    @ObservedObject var refillService = RefillPromptService.shared
    @ObservedObject var cartManager = CartManager.shared
    let onOrderSameAgain: () -> Void
    let onOrderSomethingElse: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.sunRay)
            
            // Copy
            VStack(spacing: 8) {
                Text("Been here \(refillService.sessionDurationFormatted).")
                    .font(.headline)
                    .foregroundStyle(Color.forestCanopy)
                
                Text("Need a refill?")
                    .font(.brandSerif(24))
                    .foregroundStyle(Color.forestCanopy)
            }
            
            // Actions
            HStack(spacing: 12) {
                Button {
                    onOrderSameAgain()
                } label: {
                    Text("Same again")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.forestCanopy.gradient)
                        .cornerRadius(12)
                }
                
                Button {
                    onOrderSomethingElse()
                } label: {
                    Text("Something else")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.forestCanopy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.filteredLight.opacity(0.3))
                        .cornerRadius(12)
                }
            }
            
            // Dismiss
            Button {
                refillService.dismissRefillPrompt()
            } label: {
                Text("Not now")
                    .font(.caption)
                    .foregroundStyle(Color.neutral500)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.forestCanopy.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
}

// MARK: - Refill Prompt Modifier

struct RefillPromptModifier: ViewModifier {
    @ObservedObject var refillService = RefillPromptService.shared
    @ObservedObject var quickOrderService = QuickOrderService.shared
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if refillService.showRefillPrompt {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                refillService.dismissRefillPrompt()
                            }
                        
                        RefillPromptView(
                            onOrderSameAgain: {
                                // Reorder last item
                                if let lastUsual = quickOrderService.yourUsuals.first {
                                    _ = quickOrderService.quickReorder(item: lastUsual)
                                    refillService.acceptRefillPrompt()
                                }
                            },
                            onOrderSomethingElse: {
                                // Just dismiss - user will navigate to menu
                                refillService.acceptRefillPrompt()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: refillService.showRefillPrompt)
                }
            }
    }
}

extension View {
    func withRefillPrompt() -> some View {
        modifier(RefillPromptModifier())
    }
}

// MARK: - Preview

#Preview("Refill Prompt") {
    ZStack {
        Color.morningFog.ignoresSafeArea()
        
        RefillPromptView(
            onOrderSameAgain: {},
            onOrderSomethingElse: {}
        )
    }
}
