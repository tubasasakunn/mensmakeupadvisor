import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            Group {
                switch appState.currentScreen {
                case .splash:     SplashView()
                case .onboarding: OnboardingView()
                case .home:       HomeView()
                case .capture:    AdviceView()
                case .analyzing:  AnalyzingView()
                case .diagnosis:  DiagnosisView()
                case .tutorial:   TutorialView()
                case .studio:     StudioView()
                }
            }
            .transition(reduceMotion ? .identity : .opacity)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.35),
                value: appState.currentScreen
            )
        }
        // 巨大な Dynamic Type サイズではマガジン的なタイポ階層が崩壊するので、
        // 過度な拡大を防止しつつ、視覚調整 (medium 既定の 1.4x まで) は受け付ける。
        .dynamicTypeSize(.xSmall ... .xxLarge)
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
