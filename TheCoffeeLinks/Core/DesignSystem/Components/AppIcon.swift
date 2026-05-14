import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct IconView: View {
    let name: String

    var body: some View {
        #if canImport(UIKit)
        if UIImage(named: name) != nil {
            Image(name)
                .renderingMode(.template)
        } else {
            Image(systemName: name)
        }
        #else
        Image(systemName: name)
        #endif
    }
}
