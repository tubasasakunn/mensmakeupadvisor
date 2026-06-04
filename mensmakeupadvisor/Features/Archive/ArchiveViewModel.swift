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
        appState.session.triedLooks = []
        appState.session.triedLookIndex = 0
        appState.session.loadComposition(from: look)
        appState.navigation.homeTab = .archive
        appState.session.tryingSavedLook = false
        appState.navigation.openStudio(back: .home)
    }

    // 保存ルックを別の顔で当てて見る一回限りの体験。
    // 撮影 → 解析後に Studio へ直行し、CTA は「完了」(保存しない)。
    // looks には Archive グリッドの並び順を渡す。Studio で縦スワイプして
    // 前後のルックへ切り替えられるよう、一覧と開始位置を session に預ける。
    func tryLook(_ look: SavedLook, in looks: [SavedLook], appState: AppState) {
        appState.session.triedLooks = looks
        appState.session.triedLookIndex = looks.firstIndex { $0.id == look.id } ?? 0
        appState.session.loadComposition(from: look)
        appState.navigation.homeTab = .archive
        appState.navigation.studioOrigin = .home
        appState.session.tryingSavedLook = true
        appState.navigation.openCapture(from: .home)
    }
}
