import SwiftUI

struct RootView: View {
    @StateObject private var session: AppSession

    init(container: AppContainer = .app) {
        _session = StateObject(wrappedValue: AppSession(container: container))
    }

    var body: some View {
        Group {
            switch session.flow {
            case .restoring:
                LaunchIdentityView()
            case .authentication:
                AuthFlowView(session: session)
            case .profile:
                ProfileSetupView(session: session)
            case .member:
                MemberDashboardView(session: session)
            }
        }
        .task { await session.restore() }
        .alert("common.error", isPresented: errorBinding) {
            Button("common.close", role: .cancel) { session.errorMessage = nil }
        } message: {
            Text(session.errorMessage ?? "")
        }
        .preferredColorScheme(.light)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { session.errorMessage != nil },
            set: { if !$0 { session.errorMessage = nil } }
        )
    }
}

private struct LaunchIdentityView: View {
    var body: some View {
        VStack(spacing: AppSpacing.card) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
            Text("The Coffee Links")
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)
            ProgressView().tint(AppColor.accent)
        }
        .appScreen()
    }
}
