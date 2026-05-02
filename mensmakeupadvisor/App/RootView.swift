import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            Group {
                switch appState.currentScreen {
                case .splash:     SplashView()
                case .onboarding: OnboardingView()
                case .capture:    AdviceView()
                case .analyzing:  AnalyzingView()
                case .diagnosis:  DiagnosisView()
                case .tutorial:   TutorialView()
                case .studio:     StudioView()
                case .archive:    ArchiveView()
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.35), value: appState.currentScreen)
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
