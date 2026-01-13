import Foundation

extension Double {
    /// Formats the double as a Vietnamese Dong currency string.
    /// Example: 45000.0 -> "45.000 ₫"
    func toVND() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.maximumFractionDigits = 0
        
        // Custom formatting if the default locale symbol placement isn't desired,
        // but vi_VN usually handles "45.000 ₫" correctly.
        return formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))₫"
    }
}
