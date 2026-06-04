import OSLog
import SwiftUI
import UIKit

enum AppScreen: Equatable {
    case splash, onboarding, home, capture, analyzing, diagnosis, tutorial, studio, completion, progress, mirror
}

// HomeView 内のタブ。Archive 経由で Studio に行って戻ってきた時に
// 「保存」タブを開き直したいので、選択状態を NavigationContext に上げる。
enum HomeTab: Hashable {
    case report, create, archive, settings
}

// アプリ全体の composition root。3 つの責務 (NavigationContext / MakeupSession /
// AppFlowState) を保持し、Environment にも個別に注入される。
//
// 新規実装は `appState.navigation.foo` / `appState.session.foo` / `appState.flow.foo`
// または `@Environment(NavigationContext.self)` 等で直接サブ状態にアクセスすること。
// 旧式の `appState.captureOrigin` などの平坦アクセスは後方互換用フォワードプロパティ。
@Observable @MainActor
final class AppState {
    let navigation: NavigationContext
    let session: MakeupSession
    let flow: AppFlowState

    init() {
        // 既定値は @MainActor 隔離下で生成する必要があるためデフォルト引数では渡せず、
        // 本体で初期化する。テストで差し替えたい場合は別の init を足す。
        self.navigation = NavigationContext()
        self.session = MakeupSession()
        self.flow = AppFlowState()
    }

    init(navigation: NavigationContext,
         session: MakeupSession,
         flow: AppFlowState) {
        self.navigation = navigation
        self.session = session
        self.flow = flow
    }

    func reset() {
        navigation.reset()
        session.reset()
        flow.reset()
    }

    // スクリーンショットモード: 全画面を3秒ずつ自動遷移
    func runScreenshotFlow() async {
        session.capturedImage = makePlaceholderImage()
        session.analysisResult = .mock

        let screens: [AppScreen] = [.splash, .onboarding, .home, .capture, .analyzing, .diagnosis, .tutorial, .studio, .completion]
        for screen in screens {
            navigation.navigate(to: screen)
            try? await Task.sleep(for: .seconds(3))
        }
    }

    private func makePlaceholderImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 500))
        return renderer.image { ctx in
            Theme.UIKitColor.placeholderFaceBackground.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 500))

            Theme.UIKitColor.placeholderFaceOval.setStroke()
            let face = UIBezierPath(ovalIn: CGRect(x: 85, y: 60, width: 230, height: 290))
            face.lineWidth = 1.5
            face.stroke()

            Theme.UIKitColor.placeholderFaceLine.setStroke()
            for (y, width) in [(CGFloat(165), CGFloat(160)), (210, 100), (270, 130)] as [(CGFloat, CGFloat)] {
                let line = UIBezierPath()
                line.move(to: CGPoint(x: 200 - width / 2, y: y))
                line.addLine(to: CGPoint(x: 200 + width / 2, y: y))
                line.lineWidth = 0.5
                line.stroke()
            }
        }
    }
}

// MARK: - Backward-compatible forwarding
//
// 旧 API (appState.foo) を維持するためのフォワードプロパティ。
// 段階的にサブ状態へ移行するため残しているが、新規実装では使わないこと。

extension AppState {
    // ── NavigationContext
    var currentScreen: AppScreen {
        get { navigation.currentScreen }
        set { navigation.currentScreen = newValue }
    }
    var captureOrigin: AppScreen {
        get { navigation.captureOrigin }
        set { navigation.captureOrigin = newValue }
    }
    var studioOrigin: AppScreen {
        get { navigation.studioOrigin }
        set { navigation.studioOrigin = newValue }
    }
    var diagnosisOrigin: AppScreen {
        get { navigation.diagnosisOrigin }
        set { navigation.diagnosisOrigin = newValue }
    }
    var homeTab: HomeTab {
        get { navigation.homeTab }
        set { navigation.homeTab = newValue }
    }
    func navigate(to screen: AppScreen) { navigation.navigate(to: screen) }

    // ── MakeupSession
    var capturedImage: UIImage? {
        get { session.capturedImage }
        set { session.capturedImage = newValue }
    }
    var renderedImage: UIImage? {
        get { session.renderedImage }
        set { session.renderedImage = newValue }
    }
    var analysisResult: AnalysisResult? {
        get { session.analysisResult }
        set { session.analysisResult = newValue }
    }
    var composition: MakeupComposition {
        get { session.composition }
        set { session.composition = newValue }
    }
    var activePresetID: String? {
        get { session.activePresetID }
        set { session.activePresetID = newValue }
    }
    var isRenderingMakeup: Bool {
        get { session.isRenderingMakeup }
        set { session.isRenderingMakeup = newValue }
    }
    var tryingSavedLook: Bool {
        get { session.tryingSavedLook }
        set { session.tryingSavedLook = newValue }
    }
    var makeupEngine: MakeupEngineService { session.makeupEngine }
    func requestMakeupRender() { session.requestMakeupRender() }

    // ── AppFlowState
    var tutorialStep: Int {
        get { flow.tutorialStep }
        set { flow.tutorialStep = newValue }
    }
    var tutorialDone: Bool {
        get { flow.tutorialDone }
        set { flow.tutorialDone = newValue }
    }
    var skipDiagnosisOnNextFlow: Bool {
        get { flow.skipDiagnosisOnNextFlow }
        set { flow.skipDiagnosisOnNextFlow = newValue }
    }
}
