import SwiftUI
import SwiftData

@Observable @MainActor
final class ArchiveViewModel {
    func deleteLook(_ look: SavedLook, modelContext: ModelContext) {
        modelContext.delete(look)
        try? modelContext.save()
    }

    func applyLook(_ look: SavedLook, appState: AppState) {
        loadComposition(from: look, into: appState)
        // Archive 経由の編集はオンボーディング末尾の Tutorial 工程を再び歩く。
        // 戻る先 / Home タブは編集起点が Archive である文脈を保つ。
        appState.studioOrigin = .home
        appState.homeTab = .archive
        appState.tryingSavedLook = false
        appState.navigate(to: .tutorial)
    }

    // 保存ルックを別の顔で当てて見る一回限りの体験。
    // 撮影 → 解析後に Studio へ直行し、CTA は「完了」(保存しない)。
    func tryLook(_ look: SavedLook, appState: AppState) {
        loadComposition(from: look, into: appState)
        appState.studioOrigin = .home
        appState.homeTab = .archive
        appState.tryingSavedLook = true
        appState.captureOrigin = .home
        appState.navigate(to: .capture)
    }

    private func loadComposition(from look: SavedLook, into appState: AppState) {
        appState.composition = MakeupCompositionBuilder.make(
            highlightAreas: look.highlightAreaSet,
            shadowAreas: look.shadowAreaSet,
            eyeAreas: look.eyeAreaSet,
            browType: EyebrowApplier.BrowType(rawValue: look.eyebrowTypeRaw ?? ""),
            base: Float(look.base / 100),
            highlight: Float(look.highlight / 100),
            shadow: Float(look.shadow / 100),
            eye: Float(look.eye / 100)
        )
        appState.activePresetID = look.presetID
    }
}
