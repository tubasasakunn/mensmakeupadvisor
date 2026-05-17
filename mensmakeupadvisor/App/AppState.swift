import OSLog
import SwiftUI
import UIKit

private let renderLog = Logger(subsystem: "com.tubasasakun.mensmakeupadvisor", category: "Render")

enum AppScreen: Equatable {
    case splash, onboarding, home, capture, analyzing, diagnosis, tutorial, studio, archive
}

@Observable @MainActor
final class AppState {
    var currentScreen: AppScreen = .splash
    var capturedImage: UIImage?
    var renderedImage: UIImage?
    var analysisResult: AnalysisResult? {
        didSet { applyPresetDefaultsFromAnalysisIfNeeded() }
    }
    var tutorialStep: Int = 0
    var tutorialDone: Bool = false
    var intensity: MakeupIntensity = .init()
    var activePresetID: String?
    var isRenderingMakeup: Bool = false

    // Studio で「どの highlight / shadow / eye エリアを当てるか」を multi-select
    // で持つ。target.json の area name (例: "base_t-zone") の集合。顔判定結果で
    // 初期値が決まり、ユーザーが一度でも触ったら以降は自動上書きしない。
    var highlightAreas: Set<String> = []
    var shadowAreas: Set<String> = []
    var eyeAreas: Set<String> = []

    // 眉は intensity slider ではなく type 選択で表現する。
    // nil = 眉描画 OFF。デフォルトを nil にして、ユーザーが BROW TYPE を
    // 選ぶまでは眉描画が走らないようにする (顔診断直後の画面で勝手に
    // 眉が描き換えられないように)。
    var eyebrowType: EyebrowApplier.BrowType? = nil

    // Home → Create フローでは Tutorial をスキップして直接 Studio に行く。
    // AnalyzingView 完了時の navigate 分岐で参照する。
    var skipTutorialOnNextFlow: Bool = false

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
        intensity = .init(); activePresetID = nil
        highlightAreas = []; shadowAreas = []; eyeAreas = []
        eyebrowType = nil
        presetsInitializedFromAnalysis = false
        renderTask?.cancel(); renderTask = nil
        Task { await makeupEngine.reset() }
    }

    // 顔診断完了時、ユーザーが Studio で area を触っていなければ顔型に
    // 応じたデフォルト集合を入れる。一度でも触ったら以降は上書きしない。
    private func applyPresetDefaultsFromAnalysisIfNeeded() {
        guard !presetsInitializedFromAnalysis else { return }
        let shape = analysisResult?.faceShape
        highlightAreas = MakeupAreaDefaults.highlight(for: shape)
        shadowAreas = MakeupAreaDefaults.shadow(for: shape)
        eyeAreas = MakeupAreaDefaults.eye(for: shape)
        presetsInitializedFromAnalysis = analysisResult != nil
    }

    // 化粧反映を非同期で要求する。短時間に複数回呼ばれても直近の 1 回だけ実行する。
    func requestMakeupRender() {
        renderLog.notice("requestMakeupRender: invoked — base=\(Int(self.intensity.base), privacy: .public) hl=\(Int(self.intensity.highlight), privacy: .public) sh=\(Int(self.intensity.shadow), privacy: .public) brow=\(self.eyebrowType?.rawValue ?? "off", privacy: .public)")
        renderTask?.cancel()
        // 眉は type 選択で表現。type が nil なら eyebrow intensity を 0 にして
        // 眉描画をスキップさせ、選択中ならフル強度 (100) で描画させる。
        var snapshot = intensity
        snapshot.eyebrow = eyebrowType == nil ? 0 : 100
        // ユーザーが Studio で選んだ area 集合からセレクションを構築する。
        let selection = MakeupRenderer.LayerSelection.from(
            highlightAreas: highlightAreas,
            shadowAreas: shadowAreas,
            eyeAreas: eyeAreas,
            eyebrow: eyebrowType
        )
        renderTask = Task { [weak self] in
            guard let self else { return }
            // 連続スライド時に過剰な再計算を抑える
            try? await Task.sleep(for: .milliseconds(80))
            if Task.isCancelled { return }
            self.isRenderingMakeup = true
            defer { self.isRenderingMakeup = false }
            let started = Date()
            do {
                let img = try await self.makeupEngine.render(intensity: snapshot, selection: selection)
                if Task.isCancelled { return }
                self.renderedImage = img
                let ms = Int(Date().timeIntervalSince(started) * 1000)
                renderLog.notice("render: ok in \(ms, privacy: .public)ms — base=\(Int(snapshot.base), privacy: .public) hl=\(Int(snapshot.highlight), privacy: .public) sh=\(Int(snapshot.shadow), privacy: .public) eye=\(Int(snapshot.eye), privacy: .public) brow=\(Int(snapshot.eyebrow), privacy: .public)")
            } catch {
                renderLog.error("render: failed — \(String(describing: error), privacy: .public)")
            }
        }
    }

    // スクリーンショットモード: 全画面を3秒ずつ自動遷移
    func runScreenshotFlow() async {
        capturedImage = makePlaceholderImage()
        analysisResult = .mock

        let screens: [AppScreen] = [.splash, .onboarding, .capture, .analyzing, .diagnosis, .tutorial, .studio, .archive]
        for screen in screens {
            navigate(to: screen)
            try? await Task.sleep(for: .seconds(3))
        }
    }

    private func makePlaceholderImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 500))
        return renderer.image { ctx in
            UIColor(red: 0.24, green: 0.21, blue: 0.18, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 500))

            UIColor.white.withAlphaComponent(0.45).setStroke()
            let face = UIBezierPath(ovalIn: CGRect(x: 85, y: 60, width: 230, height: 290))
            face.lineWidth = 1.5
            face.stroke()

            UIColor.white.withAlphaComponent(0.15).setStroke()
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
