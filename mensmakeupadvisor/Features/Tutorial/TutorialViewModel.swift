import SwiftUI

@Observable @MainActor
final class TutorialViewModel {
    var showBeforeImage: Bool = false

    func nextStep(appState: AppState) {
        if appState.tutorialStep < TutorialStep.all.count - 1 {
            withAnimation(.easeInOut(duration: 0.25)) { appState.tutorialStep += 1 }
        } else {
            appState.tutorialDone = true
            appState.navigate(to: .studio)
        }
    }

    func prevStep(appState: AppState) {
        if appState.tutorialStep > 0 {
            withAnimation(.easeInOut(duration: 0.25)) { appState.tutorialStep -= 1 }
        } else {
            appState.navigate(to: .diagnosis)
        }
    }

    func skip(appState: AppState) {
        appState.tutorialDone = true
        appState.navigate(to: .studio)
    }
}
