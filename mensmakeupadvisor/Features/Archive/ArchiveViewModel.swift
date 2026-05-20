import SwiftUI
import SwiftData

@Observable @MainActor
final class ArchiveViewModel {
    func deleteLook(_ look: SavedLook, modelContext: ModelContext) {
        modelContext.delete(look)
        try? modelContext.save()
    }

    func applyLook(_ look: SavedLook, appState: AppState) {
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
        // Archive 経由で Studio を開いた場合、戻る先は Home (Archive タブ) にする。
        // デフォルトの .diagnosis にすると「診断結果がない/別物」に戻ってしまい混乱する。
        appState.studioOrigin = .home
        appState.navigate(to: .studio)
    }
}
