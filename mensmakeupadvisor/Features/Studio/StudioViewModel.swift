import SwiftUI
import SwiftData

@Observable @MainActor
final class StudioViewModel {
    enum DisplayMode { case compare, fineTune }

    var displayMode: DisplayMode = .compare
    var comparePosition: CGFloat = 0.5
    var showSavedNotification: Bool = false

    func applyPreset(_ preset: MakeupPreset, appState: AppState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            preset.apply(to: &appState.composition)
        }
        appState.activePresetID = preset.id
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
        withAnimation(.easeInOut(duration: 0.25)) { showSavedNotification = true }
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.easeInOut(duration: 0.25)) { showSavedNotification = false }
            // 保存完了で home へ。CREATE フローも同じ動線になる。
            appState.navigate(to: .home)
        }
    }

    private func eyeAreaNames(_ comp: MakeupComposition) -> Set<String> {
        var names = MakeupCompositionBuilder.coveredAreaNames(.eye, unit: comp.unit(.eyeshadow))
        names.formUnion(MakeupCompositionBuilder.coveredAreaNames(.eye, unit: comp.unit(.tearbag)))
        if comp.unit(.eyeliner)?.isActive == true { names.insert("eyeliner") }
        return names
    }
}
