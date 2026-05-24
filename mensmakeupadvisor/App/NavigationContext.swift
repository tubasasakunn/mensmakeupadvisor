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
}
