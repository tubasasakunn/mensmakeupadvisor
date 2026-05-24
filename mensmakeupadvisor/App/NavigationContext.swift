import SwiftUI

// 画面遷移と「戻る」の文脈だけを保持する。
// AppScreen は RootView 全体の唯一の表示切替軸。
// capture / studio / diagnosis は複数の入口から開かれるため、
// 「戻る」を文脈ごとに正しい場所へ返すために遷移元を覚えておく。
//
// 例: Archive → applyLook → studio。このとき studio の戻るは Home へ。
// 例: Home Report → diagnosis（再閲覧）。diagnosis の戻るは Home へ。
// 例: AnalyzingView → diagnosis（新規解析）。diagnosis の戻るは capture へ。
//
// 初期値は .home — 「初回オンボーディングからの遷移」だけが例外として
// OnboardingView 側で明示的に .onboarding を立てる。
@Observable @MainActor
final class NavigationContext {
    var currentScreen: AppScreen = .splash
    var captureOrigin: AppScreen = .home
    var studioOrigin: AppScreen = .diagnosis
    var diagnosisOrigin: AppScreen = .capture

    // HomeView がどのタブを開いているか。Archive からの編集フローで
    // Studio から戻った際に Archive タブへ復帰させるための共有状態。
    var homeTab: HomeTab = .create

    func navigate(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.35)) { currentScreen = screen }
    }

    func reset() {
        captureOrigin = .home
        studioOrigin = .diagnosis
        diagnosisOrigin = .capture
        homeTab = .create
    }

    // MARK: - Router helpers
    //
    // 「origin breadcrumb をセットしてから navigate」を 1 ヶ所にまとめる。
    // 呼び出し側で順序ミスや origin の付け忘れが起こらないようにするため。
    // 引数 `from` / `back` は「ここを抜けたら戻る先」を表す。

    func openCapture(from origin: AppScreen) {
        captureOrigin = origin
        navigate(to: .capture)
    }

    func openDiagnosis(from origin: AppScreen) {
        diagnosisOrigin = origin
        navigate(to: .diagnosis)
    }

    func openStudio(back: AppScreen) {
        studioOrigin = back
        navigate(to: .studio)
    }

    func openTutorial(studioBack: AppScreen) {
        // Tutorial を通った後に Studio で「戻る」を押した時の戻り先を仕込んでおく。
        // Tutorial 自体は背景が studio と地続きなので、tutorial 自身の戻りは
        // RootView.edgeSwipeBackTarget で除外している。
        studioOrigin = studioBack
        navigate(to: .tutorial)
    }

    func openHome(tab: HomeTab) {
        homeTab = tab
        navigate(to: .home)
    }
}
