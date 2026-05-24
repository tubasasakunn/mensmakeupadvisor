import OSLog
import SwiftUI
import UIKit

private let renderLog = Logger(subsystem: "com.tubasasakun.mensmakeupadvisor", category: "Render")

enum AppScreen: Equatable {
    case splash, onboarding, home, capture, analyzing, diagnosis, tutorial, studio, completion
}

// HomeView 内のタブ。Archive 経由で Studio に行って戻ってきた時に
// 「保存」タブを開き直したいので、選択状態を AppState 側に上げる。
enum HomeTab: Hashable {
    case report, create, archive
}

@Observable @MainActor
final class AppState {
    var currentScreen: AppScreen = .splash
    var capturedImage: UIImage?
    var renderedImage: UIImage?
    var analysisResult: AnalysisResult? {
        didSet {
            applyPresetDefaultsFromAnalysisIfNeeded()
            // アーカイブのサムネイルが下地に使う「最新メッシュ」を永続化する。
            if let landmarks = analysisResult?.landmarksNormalized, !landmarks.isEmpty {
                let w = analysisResult?.imageWidthPx ?? 0
                let h = analysisResult?.imageHeightPx ?? 0
                let aspect = (w > 0 && h > 0) ? CGFloat(w) / CGFloat(h) : 4.0 / 5.0
                LatestFaceMeshStore.save(landmarksNormalized: landmarks, imageAspect: aspect)
            }
        }
    }
    var tutorialStep: Int = 0
    var tutorialDone: Bool = false
    // Studio の化粧状態。化粧単位 (MakeupUnit) ごとに meshID→色 を持つ唯一の真実。
    // 顔判定結果で初期値が決まり、ユーザーが一度でも触ったら以降は上書きしない。
    var composition: MakeupComposition = MakeupComposition()
    var activePresetID: String?
    var isRenderingMakeup: Bool = false

    // Home → Create フローでは Tutorial をスキップして直接 Studio に行く。
    // AnalyzingView 完了時の navigate 分岐で参照する。
    var skipTutorialOnNextFlow: Bool = false

    // Archive 「試す」フロー: 保存ルックを別の顔で当てて見る一回限りの体験。
    // capture → analyze 完了時に Studio へ直行し、保存もしない (Studio CTA は「完了」)。
    var tryingSavedLook: Bool = false

    // 「戻る」の文脈を保持するブレッドクラム。
    // capture / studio はオンボーディング初回フロー以外にも、Home の各タブから
    // 入ってこられるため、画面遷移元を覚えておき「戻る」をその場所へ返す。
    // 例: Archive → applyLook → studio。このとき studio の戻るは Home へ。
    // 初期値は .home — 「初回オンボーディングからの遷移」だけが例外として
    // OnboardingView 側で明示的に .onboarding を立てる。
    var captureOrigin: AppScreen = .home
    var studioOrigin: AppScreen = .diagnosis

    // HomeView がどのタブを開いているか。Archive からの編集フローで
    // Studio から戻った際に Archive タブへ復帰させるための共有状態。
    var homeTab: HomeTab = .create

    private var presetsInitializedFromAnalysis = false

    // makeup_claude のアルゴリズムを移植したエンジン。
    // アプリ全体で 1 つを使い回し、AnalyzingView で初期化 + 顔検出 →
    // Studio でレイヤー強度を変更するたびに `render` を再呼び出しする。
    let makeupEngine: MakeupEngineService = MakeupEngineService()

    private var renderTask: Task<Void, Never>?

    func navigate(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.35)) { currentScreen = screen }
    }

    func reset() {
        capturedImage = nil; renderedImage = nil; analysisResult = nil
        tutorialStep = 0; tutorialDone = false
        composition = MakeupComposition(); activePresetID = nil
        skipTutorialOnNextFlow = false
        tryingSavedLook = false
        captureOrigin = .home
        studioOrigin = .diagnosis
        homeTab = .create
        presetsInitializedFromAnalysis = false
        renderTask?.cancel(); renderTask = nil
        Task { await makeupEngine.reset() }
    }

    // 顔診断完了時、ユーザーがまだ化粧を触っていなければ顔型に応じた
    // 既定 composition を入れる。一度でも触ったら以降は上書きしない。
    // Try フロー (Archive 経由) は保存ルックの composition を保ちたいので既定を当てない。
    private func applyPresetDefaultsFromAnalysisIfNeeded() {
        guard !presetsInitializedFromAnalysis else { return }
        guard !tryingSavedLook else {
            presetsInitializedFromAnalysis = analysisResult != nil
            return
        }
        composition = MakeupCompositionBuilder.makeDefault(for: analysisResult?.faceShape)
        presetsInitializedFromAnalysis = analysisResult != nil
    }

    // 化粧反映を非同期で要求する。短時間に複数回呼ばれても直近の 1 回だけ実行する。
    func requestMakeupRender() {
        renderTask?.cancel()
        let snapshot = composition
        renderTask = Task { [weak self] in
            guard let self else { return }
            // 連続スライド時に過剰な再計算を抑える
            try? await Task.sleep(for: .milliseconds(80))
            if Task.isCancelled { return }
            self.isRenderingMakeup = true
            defer { self.isRenderingMakeup = false }
            let started = Date()
            do {
                let img = try await self.makeupEngine.render(composition: snapshot)
                if Task.isCancelled { return }
                self.renderedImage = img
                let ms = Int(Date().timeIntervalSince(started) * 1000)
                renderLog.notice("render: ok in \(ms, privacy: .public)ms")
            } catch {
                renderLog.error("render: failed — \(String(describing: error), privacy: .public)")
            }
        }
    }

    // スクリーンショットモード: 全画面を3秒ずつ自動遷移
    func runScreenshotFlow() async {
        capturedImage = makePlaceholderImage()
        analysisResult = .mock

        let screens: [AppScreen] = [.splash, .onboarding, .home, .capture, .analyzing, .diagnosis, .tutorial, .studio, .completion]
        for screen in screens {
            navigate(to: screen)
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
