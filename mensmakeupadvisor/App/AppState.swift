import SwiftUI
import UIKit

enum AppScreen: Equatable {
    case splash, onboarding, capture, analyzing, diagnosis, tutorial, studio, archive
}

@Observable @MainActor
final class AppState {
    var currentScreen: AppScreen = .splash
    var capturedImage: UIImage?
    var analysisResult: AnalysisResult?
    var tutorialStep: Int = 0
    var tutorialDone: Bool = false
    var intensity: MakeupIntensity = .init()
    var activePresetID: String?

    func navigate(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.35)) { currentScreen = screen }
    }

    func reset() {
        capturedImage = nil; analysisResult = nil
        tutorialStep = 0; tutorialDone = false
        intensity = .init(); activePresetID = nil
    }
}
