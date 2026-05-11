import SwiftUI
import UIKit

enum AppScreen: Equatable {
    case splash, onboarding, capture, analyzing, diagnosis, tutorial, studio, archive
}

@Observable @MainActor
final class AppState {
    var currentScreen: AppScreen = .splash
    var capturedImage: UIImage?
    var renderedImage: UIImage?
    var analysisResult: AnalysisResult?
    var tutorialStep: Int = 0
    var tutorialDone: Bool = false
    var intensity: MakeupIntensity = .init()
    var activePresetID: String?
    var isRenderingMakeup: Bool = false

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
        renderTask?.cancel(); renderTask = nil
        Task { await makeupEngine.reset() }
    }

    // 化粧反映を非同期で要求する。短時間に複数回呼ばれても直近の 1 回だけ実行する。
    func requestMakeupRender() {
        renderTask?.cancel()
        let snapshot = intensity
        renderTask = Task { [weak self] in
            guard let self else { return }
            // 連続スライド時に過剰な再計算を抑える
            try? await Task.sleep(for: .milliseconds(80))
            if Task.isCancelled { return }
            self.isRenderingMakeup = true
            defer { self.isRenderingMakeup = false }
            do {
                let img = try await self.makeupEngine.render(intensity: snapshot)
                if Task.isCancelled { return }
                self.renderedImage = img
            } catch {
                // エンジン未準備等は無視 (capturedImage を使う)
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
