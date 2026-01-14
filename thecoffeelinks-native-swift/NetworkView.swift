import SwiftUI

// MARK: - Legacy NetworkView (Deprecated)
// This view has been replaced by ConnectView with the new Connect/Networking feature.
// Keeping as stub for backward compatibility during transition.

struct NetworkView: View {
    var body: some View {
        // Redirect to ConnectView
        ConnectView()
    }
}

// Legacy NetworkUserCard - replaced by UserProfileSheet in Connect feature
struct NetworkUserCard: View {
    let checkIn: CheckIn
    var onBlock: () -> Void
    
    var body: some View {
        EmptyView()
    }
}
