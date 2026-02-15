import Foundation
import UIKit

class Logger {
    enum Level: String {
        case debug = "🔍"
        case info = "ℹ️"
        case warning = "⚠️"
        case error = "🚨"
    }
    
    func log(_ message: String, level: Level = .debug, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        debugLog("\(level.rawValue) [\(fileName):\(line)] \(function) -> \(message)")
        #endif
    }
}
