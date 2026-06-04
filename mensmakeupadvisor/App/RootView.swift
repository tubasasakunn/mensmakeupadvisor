import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LuxeBackground()

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
                case .completion: CompletionView()
                case .progress:   ProgressReportView()
                case .mirror:     MirrorView()
                }
            }
            .transition(reduceMotion ? .identity : .opacity)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.35),
                value: appState.currentScreen
            )
        }
        // iOS 標準のエッジスワイプ戻りを補完する。NavigationStack は採用していない
        // ので、左端 24pt 以内から右へドラッグされたら currentScreen に応じた
        // 「戻る」を呼ぶ。simultaneousGesture にすることで、画面内の他のタップや
        // スクロールを邪魔しない。Tutorial / Onboarding は内側で独自スワイプを
        // 使うので edgeSwipeBackTarget == nil として無効化する。
        .simultaneousGesture(edgeSwipeGesture)
        // 巨大な Dynamic Type サイズではマガジン的なタイポ階層が崩壊するので、
        // 過度な拡大を防止しつつ、視覚調整 (medium 既定の 1.4x まで) は受け付ける。
        .dynamicTypeSize(.xSmall ... .xxLarge)
    }

    // 画面ごとの「戻る先」マップ。nil なら戻る無効。
    // capture / studio は AppState.captureOrigin / studioOrigin を参照することで、
    // Home 経由 / Onboarding 経由 / Archive 経由などの文脈で正しい場所に戻れる。
    private var edgeSwipeBackTarget: AppScreen? {
        switch appState.currentScreen {
        case .capture:   return appState.captureOrigin
        case .diagnosis: return appState.diagnosisOrigin
        case .studio:    return appState.studioOrigin
        // Progress は Home (Archive タブ) からのみ開くので常に Home へ戻る。
        case .progress:  return .home
        // Mirror は開いた元 (既定 Studio) へ戻る。
        case .mirror:    return appState.navigation.mirrorOrigin
        // Splash/Home はトップ階層、Analyzing は処理中、
        // Tutorial/Onboarding は内側スワイプと衝突するため除外。
        // Completion は送り出し画面なので戻る対象外。
        case .splash, .home, .analyzing, .tutorial, .onboarding, .completion: return nil
        }
    }

    private var edgeSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                guard let target = edgeSwipeBackTarget else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                // 横方向に十分動き、縦のブレが少なく、左端から始まったときだけ反応
                guard dx > 80, abs(dy) < abs(dx) * 0.5,
                      value.startLocation.x < 24 else { return }
                appState.navigate(to: target)
            }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
