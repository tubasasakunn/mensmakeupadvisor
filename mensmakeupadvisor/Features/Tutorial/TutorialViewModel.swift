import SwiftUI

@Observable @MainActor
final class TutorialViewModel {
    var showBeforeImage: Bool = false

    // 顔型に応じた tutorial シーケンス。AppState.analysisResult から都度引く。
    func steps(for appState: AppState) -> [TutorialStep] {
        TutorialStep.sequence(for: appState.analysisResult?.faceShape)
    }

    // ステップ index を渡されたら、その index までを累積適用して
    // appState の intensity / area set / eyebrowType を再構成する。
    // 戻る (prev) でも次に進む (next) でも同じ関数で reset → rebuild。
    func rebuildCumulativeState(upTo index: Int, appState: AppState) {
        let seq = steps(for: appState)
        guard !seq.isEmpty else { return }
        let target = min(max(index, 0), seq.count - 1)

        // reset
        appState.intensity = MakeupIntensity()
        appState.highlightAreas = []
        appState.shadowAreas = []
        appState.eyeAreas = []
        appState.eyebrowType = nil

        for i in 0...target {
            apply(step: seq[i], appState: appState)
        }
    }

    private func apply(step: TutorialStep, appState: AppState) {
        switch step.layer {
        case .base:
            appState.intensity.base = max(appState.intensity.base, 40)
        case .highlight:
            if let area = step.areaName { appState.highlightAreas.insert(area) }
            appState.intensity.highlight = max(appState.intensity.highlight, 50)
        case .shadow:
            if let area = step.areaName { appState.shadowAreas.insert(area) }
            appState.intensity.shadow = max(appState.intensity.shadow, 35)
        case .eye:
            if let area = step.areaName { appState.eyeAreas.insert(area) }
            appState.intensity.eye = max(appState.intensity.eye, 40)
        case .eyebrow:
            if let raw = step.areaName, let bt = EyebrowApplier.BrowType(rawValue: raw) {
                appState.eyebrowType = bt
            }
        }
    }

    func nextStep(appState: AppState) {
        let seq = steps(for: appState)
        if appState.tutorialStep < seq.count - 1 {
            withAnimation(.easeInOut(duration: 0.25)) {
                appState.tutorialStep += 1
            }
            rebuildCumulativeState(upTo: appState.tutorialStep, appState: appState)
        } else {
            // 最終ステップで NEXT → Studio へ。Studio で保存後に home に飛ばす。
            appState.tutorialDone = true
            appState.navigate(to: .studio)
        }
    }

    func prevStep(appState: AppState) {
        if appState.tutorialStep > 0 {
            withAnimation(.easeInOut(duration: 0.25)) {
                appState.tutorialStep -= 1
            }
            rebuildCumulativeState(upTo: appState.tutorialStep, appState: appState)
        } else {
            appState.navigate(to: .diagnosis)
        }
    }

    func skip(appState: AppState) {
        // 全部入りの最終形を Studio に持ち越す
        let seq = steps(for: appState)
        if !seq.isEmpty {
            rebuildCumulativeState(upTo: seq.count - 1, appState: appState)
        }
        appState.tutorialDone = true
        appState.navigate(to: .studio)
    }

    // Tutorial 画面に入ったタイミングで「step 0 まで」の状態に初期化する。
    func resetToFirstStep(appState: AppState) {
        appState.tutorialStep = 0
        rebuildCumulativeState(upTo: 0, appState: appState)
    }
}
