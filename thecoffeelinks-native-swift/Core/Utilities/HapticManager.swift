import UIKit
import CoreHaptics

class HapticManager: HapticServiceProtocol, @unchecked Sendable {
    private var engine: CHHapticEngine?
    
    init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptics error: \(error.localizedDescription)")
        }
    }
    
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    func playLightImpact() {
         let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func playMediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // MARK: - HapticServiceProtocol Implementation
    
    func impact(_ style: HapticStyle) async {
        await MainActor.run {
            let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
            switch style {
            case .light: uiStyle = .light
            case .medium: uiStyle = .medium
            case .heavy: uiStyle = .heavy
            case .soft: uiStyle = .soft
            case .rigid: uiStyle = .rigid
            }
            let generator = UIImpactFeedbackGenerator(style: uiStyle)
            generator.impactOccurred()
        }
    }
    
    func notification(_ type: HapticNotificationType) async {
        await MainActor.run {
            let uiType: UINotificationFeedbackGenerator.FeedbackType
            switch type {
            case .success: uiType = .success
            case .warning: uiType = .warning
            case .error: uiType = .error
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(uiType)
        }
    }
    
    func selection() async {
        await MainActor.run {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}
