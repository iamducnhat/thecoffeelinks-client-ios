//
//  AppState.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    // MARK: - Core Modes
    enum TimeMode {
        case morning // 6am - 11am (Coffee first)
        case day     // 11am - 5pm (Work/Connect)
        case evening // 5pm+ (Chill/Events)
    }
    
    enum UserActivity {
        case idle
        case activeOrder(id: String, status: String)
        case checkedIn(location: String)
        case browsingMenu
    }
    
    // MARK: - Published State
    @Published var timeMode: TimeMode = .morning
    @Published var userActivity: UserActivity = .idle
    @Published var userName: String = "Nhat"
    
    // MARK: - Derived "Thesis" States
    var topIntent: String? {
        switch userActivity {
        case .activeOrder(_, let status):
            return "Order \(status)"
        case .checkedIn(let location):
            return "You are at \(location)"
        case .idle:
            return timeMode == .morning ? "Morning Fuel" : nil
        default:
            return nil
        }
    }
    
    init() {
        determineTimeMode()
    }
    
    func determineTimeMode() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 11 {
            timeMode = .morning
        } else if hour < 17 {
            timeMode = .day
        } else {
            timeMode = .evening
        }
    }
}
