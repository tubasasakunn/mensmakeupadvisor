import SwiftUI
import UIKit

enum AppScreen: Equatable {
    case splash, onboarding, capture, analyzing, diagnosis, tutorial, studio, archive
}

@Observable @MainActor
final class AppState {
    var currentScreen: AppScreen = .splash
    var capturedImage: UIImage?
    var analysisResult: AnalysisResult?
    var tutorialStep: Int = 0
    var tutorialDone: Bool = false
    var intensity: MakeupIntensity = .init()
    var activePresetID: String?

    func navigate(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.35)) { currentScreen = screen }
    }

    func reset() {
        capturedImage = nil; analysisResult = nil
        tutorialStep = 0; tutorialDone = false
        intensity = .init(); activePresetID = nil
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

            // 顔の輪郭
            UIColor.white.withAlphaComponent(0.45).setStroke()
            let face = UIBezierPath(ovalIn: CGRect(x: 85, y: 60, width: 230, height: 290))
            face.lineWidth = 1.5
            face.stroke()

            // 参照ライン（目・鼻・口の位置）
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
