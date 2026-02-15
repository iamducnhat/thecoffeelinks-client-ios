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
///
/// Marked `nonisolated` so it can be called from any actor/isolation context
/// (background Tasks, Sendable closures, etc.) without compiler errors.
@inline(__always)
nonisolated func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    print(output, terminator: terminator)
    #endif
}
