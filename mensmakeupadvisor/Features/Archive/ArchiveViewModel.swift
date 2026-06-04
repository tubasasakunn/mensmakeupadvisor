import SwiftUI
import SwiftData

@Observable @MainActor
final class ArchiveViewModel {
    func deleteLook(_ look: SavedLook, modelContext: ModelContext) {
        modelContext.delete(look)
        try? modelContext.save()
    }

    // 保存ルックの設定を Studio で開き直して微調整する。
    // composition を AppState に焼き込んだうえで Studio 直行
    // (Tutorial をやり直させない: 編集者は既に組み終わっている前提)。
    func applyLook(_ look: SavedLook, appState: AppState) {
        loadComposition(from: look, into: appState)
        appState.navigation.homeTab = .archive
        appState.session.tryingSavedLook = false
        appState.navigation.openStudio(back: .home)
    }

    // 保存ルックを別の顔で当てて見る一回限りの体験。
    // 撮影 → 解析後に Studio へ直行し、CTA は「完了」(保存しない)。
    func tryLook(_ look: SavedLook, appState: AppState) {
        loadComposition(from: look, into: appState)
        appState.navigation.homeTab = .archive
        appState.navigation.studioOrigin = .home
        appState.session.tryingSavedLook = true
        appState.navigation.openCapture(from: .home)
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
