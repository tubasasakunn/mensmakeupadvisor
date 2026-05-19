import SwiftUI

@Observable @MainActor
final class TutorialViewModel {
    // step.id → スライダー値 (0-100)。未設定の step はレイヤー既定値を使う。
    // 1 step = 1 部位なので、スライダーはその step の部位だけを調整する。
    private var stepIntensity: [String: Double] = [:]

    // 眉ステップで選んだタイプ。render と最終 composition に使う。
    var eyebrowType: EyebrowApplier.BrowType?

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
        eyebrowType = nil
        appState.tutorialStep = 0
        appState.renderedImage = nil
    }

    func nextStep(appState: AppState) {
        let seq = steps(for: appState)
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
        let seq = steps(for: appState)
        // skip 時など眉未選択ならおすすめタイプを既定で入れる。
        if eyebrowType == nil,
           let browStep = seq.last(where: { $0.layer == .eyebrow }),
           let raw = browStep.areaName,
           let bt = EyebrowApplier.BrowType(rawValue: raw) {
            eyebrowType = bt
        }
        appState.composition = buildComposition(appState: appState, upto: seq.count - 1)
        appState.tutorialDone = true
        appState.navigate(to: .studio)
    }

    // 眉 step に到達したら、未選択ならおすすめタイプを既定で入れて効果を見せる。
    private func prepareEyebrowDefaultIfNeeded(appState: AppState) {
        let seq = steps(for: appState)
        let idx = appState.tutorialStep
        guard idx >= 0, idx < seq.count, seq[idx].layer == .eyebrow else { return }
        if eyebrowType == nil, let raw = seq[idx].areaName,
           let bt = EyebrowApplier.BrowType(rawValue: raw) {
            eyebrowType = bt
        }
    }

    // MARK: - Render

    // 現在の step までを 1 部位ずつ重ねた化粧を非同期で反映する。
    func render(appState: AppState) async {
        // 連続スライド時に過剰な再計算を抑える
        try? await Task.sleep(for: .milliseconds(80))
        if Task.isCancelled { return }
        let composition = buildComposition(appState: appState, upto: appState.tutorialStep)
        guard let img = try? await appState.makeupEngine.render(composition: composition) else { return }
        if Task.isCancelled { return }
        appState.renderedImage = img
    }

    // 到達済みの step (0...upto) だけを 1 部位ずつ重ねた composition を組む。
    private func buildComposition(appState: AppState, upto rawUpto: Int) -> MakeupComposition {
        let seq = steps(for: appState)
        guard !seq.isEmpty else { return MakeupComposition() }
        let upto = max(0, min(rawUpto, seq.count - 1))
        var comp = MakeupComposition()
        var eyebrowReached = false

        for step in seq.prefix(upto + 1) {
            let alpha = Float(max(0, min(100, intensity(for: step))) / 100)
            switch step.layer {
            case .base:
                comp.setUnit(MakeupUnit(kind: .base, tint: MakeupKind.base.color(intensity: alpha)))
            case .highlight:
                if let area = step.areaName {
                    addMeshColors(&comp, kind: .highlight,
                                  meshIDs: MakeupCompositionBuilder.meshIDs(.highlight, names: [area]),
                                  alpha: alpha)
                }
            case .shadow:
                if let area = step.areaName {
                    addMeshColors(&comp, kind: .shadow,
                                  meshIDs: MakeupCompositionBuilder.meshIDs(.shadow, names: [area]),
                                  alpha: alpha)
                }
            case .eye:
                if let area = step.areaName {
                    let kind = MakeupKind.eyeKind(forArea: area)
                    if kind == .eyeliner {
                        comp.setUnit(MakeupUnit(kind: .eyeliner,
                                                tint: MakeupKind.eyeliner.color(intensity: alpha)))
                    } else {
                        addMeshColors(&comp, kind: kind,
                                      meshIDs: MakeupCompositionBuilder.eyeMeshIDs(kind: kind, names: [area]),
                                      alpha: alpha)
                    }
                }
            case .eyebrow:
                eyebrowReached = true
            }
        }

        if eyebrowReached, let browType = eyebrowType {
            var brow = MakeupUnit(kind: .eyebrow, tint: MakeupKind.eyebrow.color(intensity: 1))
            brow.browType = browType
            comp.setUnit(brow)
        }
        return comp
    }

    private func addMeshColors(_ comp: inout MakeupComposition, kind: MakeupKind,
                               meshIDs: [Int], alpha: Float) {
        var unit = comp.unit(kind) ?? MakeupUnit(kind: kind)
        let color = kind.color(intensity: alpha)
        for id in meshIDs { unit.meshColors[id] = color }
        comp.setUnit(unit)
    }
}
