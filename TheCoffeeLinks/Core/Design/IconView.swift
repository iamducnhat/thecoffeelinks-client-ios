import SwiftUI

struct IconView: View {
    let name: String
    var size: CGFloat = 18

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .medium))
            .accessibilityHidden(true)
    }
}
