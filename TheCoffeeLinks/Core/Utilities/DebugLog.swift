//
//  DebugLog.swift
//  TheCoffeeLinks
//
//  Compile-time gated logging. In Release builds, these are completely eliminated
//  by the compiler — zero overhead for production users.
//

import Foundation

/// Drop-in replacement for `print()` that is stripped in Release builds.
/// Usage: `debugLog("🌐 Request →", method, url)`
@inline(__always)
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    print(output, terminator: terminator)
    #endif
}
