import Combine
import Foundation
import SwiftUI

@MainActor
final class AppSession: ObservableObject {
    enum Flow: Equatable { case restoring, authentication, profile, member }

    @Published private(set) var flow: Flow = .restoring
    @Published private(set) var member: Member?
    @Published private(set) var history: [PointTransaction] = []
    @Published private(set) var nextCursor: String?
    @Published private(set) var memberQR: MemberQR?
    @Published private(set) var isOffline = false
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?

    private let auth: any AuthRepositoryProtocol
    private let loyalty: any LoyaltyRepositoryProtocol
    private(set) var pendingPhone = ""

    init(container: AppContainer) {
        auth = container.auth
        loyalty = container.loyalty
    }

    func restore() async {
        guard await auth.hasSession() else {
            flow = .authentication
            return
        }
        await loadSnapshot(allowCache: true)
    }

    func sendOTP(phone: String) async -> Bool {
        let normalized = Self.normalize(phone)
        guard normalized.count >= 10 else {
            errorMessage = String(localized: "auth.invalid_phone")
            return false
        }
        return await run {
            try await auth.sendOTP(to: normalized)
            pendingPhone = normalized
        }
    }

    func verifyOTP(_ code: String) async -> Bool {
        guard code.count == 6 else {
            errorMessage = String(localized: "auth.invalid_otp")
            return false
        }
        let success = await run { try await auth.verifyOTP(phone: pendingPhone, code: code) }
        if success { await loadSnapshot(allowCache: false) }
        return success
    }

    func saveName(_ name: String) async -> Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanName.count >= 2 else {
            errorMessage = String(localized: "profile.invalid_name")
            return false
        }
        let success = await run { try await auth.updateName(cleanName) }
        if success { await loadSnapshot(allowCache: false) }
        return success
    }

    func refresh() async { await loadSnapshot(allowCache: true) }

    func loadMoreHistory() async {
        guard let cursor = nextCursor, !isBusy else { return }
        let success = await run {
            let snapshot = try await loyalty.memberSnapshot(cursor: cursor)
            history.append(contentsOf: snapshot.1.items.filter { item in !history.contains(where: { $0.id == item.id }) })
            nextCursor = snapshot.1.nextCursor
        }
        if !success { errorMessage = nil }
    }

    func refreshQR(force: Bool = false) async {
        if !force, let qr = memberQR, qr.secondsRemaining() > 60 { return }
        do {
            memberQR = try await loyalty.memberQR()
            isOffline = false
        } catch APIError.offline {
            isOffline = true
            if memberQR?.isExpired() == true { memberQR = nil }
        } catch {
            if memberQR?.isExpired() == true { memberQR = nil }
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        await auth.signOut()
        member = nil
        history = []
        memberQR = nil
        pendingPhone = ""
        flow = .authentication
    }

    func sendDeletionOTP() async -> Bool {
        guard let phone = member?.phone else { return false }
        return await run { try await auth.sendOTP(to: phone) }
    }

    func deleteAccount(otp: String) async -> Bool {
        guard let phone = member?.phone, otp.count == 6 else {
            errorMessage = String(localized: "auth.invalid_otp")
            return false
        }
        let success = await run { try await auth.deleteAccount(phone: phone, otp: otp) }
        if success {
            member = nil
            history = []
            memberQR = nil
            flow = .authentication
        }
        return success
    }

    private func loadSnapshot(allowCache: Bool) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let snapshot = try await loyalty.memberSnapshot(cursor: nil)
            apply(snapshot)
            isOffline = false
        } catch {
            if allowCache, let cached = await loyalty.cachedSnapshot() {
                apply(cached)
                isOffline = true
            } else if error is APIError {
                errorMessage = error.localizedDescription
                flow = await auth.hasSession() ? .member : .authentication
            } else {
                errorMessage = error.localizedDescription
                flow = .authentication
            }
        }
    }

    private func apply(_ snapshot: (Member, HistoryPage)) {
        member = snapshot.0
        history = snapshot.1.items
        nextCursor = snapshot.1.nextCursor
        flow = snapshot.0.needsName ? .profile : .member
    }

    private func run(_ operation: () async throws -> Void) async -> Bool {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await operation()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    static func normalize(_ phone: String) -> String {
        let clean = phone.filter { $0.isNumber || $0 == "+" }
        if clean.hasPrefix("0") { return "+84" + clean.dropFirst() }
        if clean.hasPrefix("84") { return "+" + clean }
        return clean
    }
}
