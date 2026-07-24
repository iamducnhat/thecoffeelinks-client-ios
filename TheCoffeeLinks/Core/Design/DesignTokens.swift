import SwiftUI

enum AppColor {
    static let background = Color("Colors/BackgroundPaper")
    static let surface = Color("Colors/SurfaceCard")
    static let elevated = Color.white
    static let textPrimary = Color("Colors/TextInk")
    static let textSecondary = Color("Colors/TextMuted")
    static let accent = Color("Colors/PrimaryEspresso")
    static let accentForeground = Color("Colors/BackgroundPaper")
    static let border = Color("Colors/Border")
    static let borderMuted = Color("Colors/BorderTertiary")
    static let success = Color("Colors/SemanticSuccess")
    static let warning = Color("Colors/SemanticWarning")
    static let error = Color("Colors/SemanticError")
}

enum AppSpacing {
    static let screen: CGFloat = 23
    static let section: CGFloat = 40
    static let card: CGFloat = 13
    static let row: CGFloat = 13
    static let compact: CGFloat = 8
    static let micro: CGFloat = 4
    static let touchTarget: CGFloat = 44
    static let buttonHeight: CGFloat = 38
    static let fieldHeight: CGFloat = 49
    static let rowHeight: CGFloat = 49
    static let badgeHeight: CGFloat = 26
    static let cornerRadius: CGFloat = 0
    static let borderWidth: CGFloat = 1
}

enum AppFont {
    static let screenTitle = Font.custom("BeVietnamPro-Bold", size: 22)
    static let sectionTitle = Font.custom("BeVietnamPro-SemiBold", size: 22)
    static let cardTitle = Font.custom("BeVietnamPro-SemiBold", size: 18)
    static let body = Font.custom("BeVietnamPro-Medium", size: 18)
    static let bodyStrong = Font.custom("BeVietnamPro-SemiBold", size: 18)
    static let label = Font.custom("BeVietnamPro-Medium", size: 14)
    static let labelStrong = Font.custom("BeVietnamPro-SemiBold", size: 14)
    static let button = Font.custom("BeVietnamPro-SemiBold", size: 14)
    static let points = Font.custom("NotoSansMono-Medium", size: 32)
    static let mono = Font.custom("NotoSansMono-Medium", size: 17)
    static let monoSmall = Font.custom("NotoSansMono-Regular", size: 13)
}

extension View {
    func appScreen() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.background.ignoresSafeArea())
    }
}
