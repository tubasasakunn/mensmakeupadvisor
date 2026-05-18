import SwiftUI

@Observable @MainActor
final class TutorialViewModel {
    // step.id → スライダー値 (0-100)。未設定の step はレイヤー既定値を使う。
    // 1 step = 1 部位なので、スライダーはその step の部位だけを調整する。
    private var stepIntensity: [String: Double] = [:]

    // 顔型に応じた tutorial シーケンス。AppState.analysisResult から都度引く。
    func steps(for appState: AppState) -> [TutorialStep] {
        TutorialStep.sequence(for: appState.analysisResult?.faceShape)
    }

    // MARK: - Per-step intensity

    func intensity(for step: TutorialStep) -> Double {
        stepIntensity[step.id] ?? Self.defaultIntensity(for: step.layer)
    }

    func setIntensity(_ value: Double, for step: TutorialStep) {
        stepIntensity[step.id] = value
    }

    private static func defaultIntensity(for layer: MakeupLayer) -> Double {
        switch layer {
        case .base:      return 40
        case .highlight: return 50
        case .shadow:    return 35
        case .eye:       return 40
        case .eyebrow:   return 100
        }
    }

    // MARK: - Lifecycle

    // Tutorial 入場時の初期化。step 0 に戻し、化粧プレビューも素の状態に戻す。
    func resetToFirstStep(appState: AppState) {
        stepIntensity = [:]
        appState.tutorialStep = 0
        appState.eyebrowType = nil
        appState.renderedImage = nil
    }

    func nextStep(appState: AppState) {
        let seq = steps(for: appState)
        // 最終ステップで次へ → Studio に渡す状態を確定してから遷移
        guard appState.tutorialStep < seq.count - 1 else {
            finishToStudio(appState: appState)
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            appState.tutorialStep += 1
        }
        prepareEyebrowDefaultIfNeeded(appState: appState)
    }

    func prevStep(appState: AppState) {
        guard appState.tutorialStep > 0 else {
            appState.navigate(to: .diagnosis)
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            appState.tutorialStep -= 1
        }
    }

    func skip(appState: AppState) {
        finishToStudio(appState: appState)
    }

    private func finishToStudio(appState: AppState) {
        finalizeForStudio(appState: appState)
        appState.tutorialDone = true
        appState.navigate(to: .studio)
    }

    // 眉 step に到達したら、未選択ならおすすめタイプを既定で入れて効果を見せる。
    private func prepareEyebrowDefaultIfNeeded(appState: AppState) {
        let seq = steps(for: appState)
        let idx = appState.tutorialStep
        guard idx >= 0, idx < seq.count, seq[idx].layer == .eyebrow else { return }
        let step = seq[idx]
        if appState.eyebrowType == nil, let raw = step.areaName,
           let bt = EyebrowApplier.BrowType(rawValue: raw) {
            appState.eyebrowType = bt
        }
    }

    // MARK: - Render

    // 現在の step までを 1 部位ずつ重ねた化粧を非同期で反映する。
    func render(appState: AppState) async {
        // 連続スライド時に過剰な再計算を抑える
        try? await Task.sleep(for: .milliseconds(80))
        if Task.isCancelled { return }
        let (intensities, selection) = buildRender(appState: appState)
        guard let img = try? await appState.makeupEngine.render(
            intensity: intensities, selection: selection
        ) else { return }
        if Task.isCancelled { return }
        appState.renderedImage = img
    }

    // 到達済みの step (0...current) だけを使って描画指示を組み立てる。
    private func buildRender(appState: AppState) -> (MakeupIntensity, MakeupRenderer.LayerSelection) {
        let seq = steps(for: appState)
        guard !seq.isEmpty else { return (MakeupIntensity(), .default) }
        let upto = max(0, min(appState.tutorialStep, seq.count - 1))

        var intensities = MakeupIntensity()
        var highlightAreas: [String] = []
        var shadowAreas: [String] = []
        var eyeAreas: [String] = []
        var areaIntensities: [String: Float] = [:]
        var eyebrowReached = false

        for step in seq.prefix(upto + 1) {
            let value = intensity(for: step)
            let scale = Float(max(0, min(100, value)) / 100)
            switch step.layer {
            case .base:
                intensities.base = value
            case .highlight:
                if let area = step.areaName {
                    highlightAreas.append(area)
                    areaIntensities[area] = scale
                }
                intensities.highlight = 100
            case .shadow:
                if let area = step.areaName {
                    shadowAreas.append(area)
                    areaIntensities[area] = scale
                }
                intensities.shadow = 100
            case .eye:
                if let area = step.areaName {
                    eyeAreas.append(area)
                    areaIntensities[area] = scale
                }
                intensities.eye = 100
            case .eyebrow:
                eyebrowReached = true
            }
        }

        if eyebrowReached, appState.eyebrowType != nil {
            intensities.eyebrow = 100
        }

        let selection = MakeupRenderer.LayerSelection(
            highlightAreaNames: highlightAreas,
            shadowAreaNames: shadowAreas,
            applyBase: true,
            eyeAreaNames: eyeAreas,
            applyEyeliner: eyeAreas.contains("eyeliner"),
            eyebrowType: appState.eyebrowType ?? .natural,
            areaIntensities: areaIntensities
        )
        return (intensities, selection)
    }

    // Studio はレイヤー単位の強度で動くため、tutorial の全 step を集約して
    // AppState に書き戻す。部位ごとの差は各レイヤーの最大値に丸める。
    private func finalizeForStudio(appState: AppState) {
        let seq = steps(for: appState)
        var intensities = MakeupIntensity()
        var highlightAreas: Set<String> = []
        var shadowAreas: Set<String> = []
        var eyeAreas: Set<String> = []

        for step in seq {
            let value = intensity(for: step)
            switch step.layer {
            case .base:
                intensities.base = value
            case .highlight:
                if let area = step.areaName { highlightAreas.insert(area) }
                intensities.highlight = max(intensities.highlight, value)
            case .shadow:
                if let area = step.areaName { shadowAreas.insert(area) }
                intensities.shadow = max(intensities.shadow, value)
            case .eye:
                if let area = step.areaName { eyeAreas.insert(area) }
                intensities.eye = max(intensities.eye, value)
            case .eyebrow:
                break
            }
        }

        appState.intensity = intensities
        appState.highlightAreas = highlightAreas
        appState.shadowAreas = shadowAreas
        appState.eyeAreas = eyeAreas
    }
}
