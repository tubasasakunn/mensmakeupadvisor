import SwiftUI

@Observable @MainActor
final class TutorialViewModel {
    var showBeforeImage: Bool = false

    // 顔型に応じた tutorial シーケンス。AppState.analysisResult から都度引く。
    func steps(for appState: AppState) -> [TutorialStep] {
        TutorialStep.sequence(for: appState.analysisResult?.faceShape)
    }

    // Tutorial 入場時の初期化。全状態を一度クリアして step 0 (base) を適用する。
    func resetToFirstStep(appState: AppState) {
        appState.tutorialStep = 0
        appState.intensity = MakeupIntensity()
        appState.highlightAreas = []
        appState.shadowAreas = []
        appState.eyeAreas = []
        appState.eyebrowType = nil
        if let first = steps(for: appState).first {
            apply(step: first, appState: appState)
        }
    }

    func nextStep(appState: AppState) {
        let seq = steps(for: appState)
        // 最終ステップで次へ → Studio で保存できる状態にしてから遷移
        guard appState.tutorialStep < seq.count - 1 else {
            appState.tutorialDone = true
            appState.navigate(to: .studio)
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            appState.tutorialStep += 1
        }
        apply(step: seq[appState.tutorialStep], appState: appState)
    }

    func prevStep(appState: AppState) {
        let seq = steps(for: appState)
        guard appState.tutorialStep > 0 else {
            appState.navigate(to: .diagnosis)
            return
        }
        // 「今の step を打ち消してから」前に戻る。intensity はユーザーが
        // 調整した値を保持するため、resetToFirstStep のような全消しはしない。
        unapply(step: seq[appState.tutorialStep], appState: appState)
        withAnimation(.easeInOut(duration: 0.25)) {
            appState.tutorialStep -= 1
        }
    }

    func skip(appState: AppState) {
        // 全 step を一括適用してから Studio へ
        for step in steps(for: appState) {
            apply(step: step, appState: appState)
        }
        appState.tutorialDone = true
        appState.navigate(to: .studio)
    }

    // MARK: - Apply / Unapply

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

    private func unapply(step: TutorialStep, appState: AppState) {
        switch step.layer {
        case .base:
            appState.intensity.base = 0
        case .highlight:
            if let area = step.areaName { appState.highlightAreas.remove(area) }
            if appState.highlightAreas.isEmpty { appState.intensity.highlight = 0 }
        case .shadow:
            if let area = step.areaName { appState.shadowAreas.remove(area) }
            if appState.shadowAreas.isEmpty { appState.intensity.shadow = 0 }
        case .eye:
            if let area = step.areaName { appState.eyeAreas.remove(area) }
            if appState.eyeAreas.isEmpty { appState.intensity.eye = 0 }
        case .eyebrow:
            appState.eyebrowType = nil
        }
    }
}
