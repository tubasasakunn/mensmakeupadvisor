import SwiftUI
import SwiftData

@Observable @MainActor
final class ArchiveViewModel {
    func deleteLook(_ look: SavedLook, modelContext: ModelContext) {
        modelContext.delete(look)
        try? modelContext.save()
    }

    func applyLook(_ look: SavedLook, appState: AppState) {
        appState.intensity = MakeupIntensity(
            base: look.base,
            highlight: look.highlight,
            shadow: look.shadow,
            eye: look.eye,
            eyebrow: look.eyebrow
        )
        appState.activePresetID = look.presetID
        appState.navigate(to: .studio)
    }
}
