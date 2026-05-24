import SwiftUI

// 「今どんなフローを走らせている最中か」を表す一時フラグ群。
// 画面状態でも撮影セッションでもなく「一度きりの分岐ルール」。
@Observable @MainActor
final class AppFlowState {
    var tutorialStep: Int = 0
    var tutorialDone: Bool = false

    // Home → Create フローでは Diagnosis を飛ばして直接 Tutorial（各化粧工程の
    // ガイド）に入る。撮って即「試す」体験を最短化するため。
    // AnalyzingView 完了時の navigate 分岐で参照する。
    var skipDiagnosisOnNextFlow: Bool = false

    func reset() {
        tutorialStep = 0
        tutorialDone = false
        skipDiagnosisOnNextFlow = false
    }
}
