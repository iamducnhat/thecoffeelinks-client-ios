import SwiftUI

struct AppCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(AppLayout.spacing)
            .background(Color.surfaceCard)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(Color.border, lineWidth: AppLayout.borderWidth)
            )
    }
}

struct AppCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.backgroundPaper.ignoresSafeArea()
            
            AppCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Card Title").fontTitle()
                    Text("This is a generic card component respecting the design system.").fontBody()
                }
            }
            .padding()
        }
    }
}
