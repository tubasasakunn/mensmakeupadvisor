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
            appState.intensity = preset.intensity
        }
        appState.activePresetID = preset.id
    }

    func saveLook(appState: AppState, modelContext: ModelContext) {
        let look = SavedLook(
            id: UUID().uuidString,
            createdAt: .now,
            presetID: appState.activePresetID,
            totalScore: appState.analysisResult?.totalScore ?? 0,
            faceShape: appState.analysisResult?.faceShape.rawValue ?? "",
            base: appState.intensity.base,
            highlight: appState.intensity.highlight,
            shadow: appState.intensity.shadow,
            eye: appState.intensity.eye,
            eyebrow: appState.intensity.eyebrow
        )
        modelContext.insert(look)
        try? modelContext.save()
        withAnimation(.easeInOut(duration: 0.25)) { showSavedNotification = true }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeInOut(duration: 0.25)) { showSavedNotification = false }
        }
    }
}
