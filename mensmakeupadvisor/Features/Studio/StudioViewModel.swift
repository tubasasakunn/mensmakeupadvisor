import SwiftUI
import SwiftData

@Observable @MainActor
final class StudioViewModel {
    enum DisplayMode { case compare, fineTune }

    var displayMode: DisplayMode = .compare
    var comparePosition: CGFloat = 0.5
    var showSavedNotification: Bool = false

    // 何か触られているか。リセットボタンの表示判定に使う。
    func hasAnyIntensity(_ comp: MakeupComposition) -> Bool {
        for kind in MakeupKind.allCases where comp.intensity(of: kind) > 0.001 {
            return true
        }
        return comp.browType != nil
    }

    func applyPreset(_ preset: MakeupPreset, appState: AppState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            preset.apply(to: &appState.composition)
        }
        appState.activePresetID = preset.id
    }

    // 全化粧単位の強度を 0 に戻し、眉も解除する。プリセットの選択状態も解除。
    func resetAll(appState: AppState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            for kind in MakeupKind.allCases {
                appState.composition.setIntensity(0, for: kind)
            }
            appState.composition.setBrowType(nil)
            appState.activePresetID = nil
        }
    }

    func saveLook(appState: AppState, modelContext: ModelContext) {
        let comp = appState.composition
        let eyeIntensity = max(comp.intensity(of: .eyeshadow),
                               comp.intensity(of: .tearbag),
                               comp.intensity(of: .eyeliner))
        let look = SavedLook(
            id: UUID().uuidString,
            createdAt: .now,
            presetID: appState.activePresetID,
            totalScore: appState.analysisResult?.totalScore ?? 0,
            faceShape: appState.analysisResult?.faceShape.rawValue ?? "",
            base: Double(comp.intensity(of: .base)) * 100,
            highlight: Double(comp.intensity(of: .highlight)) * 100,
            shadow: Double(comp.intensity(of: .shadow)) * 100,
            eye: Double(eyeIntensity) * 100,
            eyebrow: Double(comp.intensity(of: .eyebrow)) * 100,
            highlightAreas: MakeupCompositionBuilder.coveredAreaNames(.highlight, unit: comp.unit(.highlight)),
            shadowAreas: MakeupCompositionBuilder.coveredAreaNames(.shadow, unit: comp.unit(.shadow)),
            eyeAreas: eyeAreaNames(comp),
            eyebrowTypeRaw: comp.browType?.rawValue
        )
        modelContext.insert(look)
        try? modelContext.save()
        // トーストは長めに表示（保存できたことを確認できる時間を確保）し、
        // 自動遷移はしない。ユーザーが「ホームへ」「編集を続ける」を自分で選ぶ。
        withAnimation(.easeInOut(duration: 0.25)) { showSavedNotification = true }
    }

    func dismissSavedNotification() {
        withAnimation(.easeInOut(duration: 0.25)) { showSavedNotification = false }
    }

    private func eyeAreaNames(_ comp: MakeupComposition) -> Set<String> {
        var names = MakeupCompositionBuilder.coveredAreaNames(.eye, unit: comp.unit(.eyeshadow))
        names.formUnion(MakeupCompositionBuilder.coveredAreaNames(.eye, unit: comp.unit(.tearbag)))
        if comp.unit(.eyeliner)?.isActive == true { names.insert("eyeliner") }
        return names
    }
}
