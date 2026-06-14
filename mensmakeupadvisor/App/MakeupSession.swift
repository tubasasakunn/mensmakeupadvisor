import OSLog
import SwiftUI
import UIKit

private let sessionLog = Logger(subsystem: "com.tubasasakun.mensmakeupadvisor", category: "MakeupSession")

// 撮影画像・診断結果・化粧 composition と、それを反映する MakeupEngine をまとめた
// 「1 セッション分の状態」。Capture → Analyze → Studio が共有する唯一の真実。
@Observable @MainActor
final class MakeupSession {
    var capturedImage: UIImage?
    var renderedImage: UIImage?
    var analysisResult: AnalysisResult? {
        didSet {
            applyPresetDefaultsFromAnalysisIfNeeded()
            // アーカイブのサムネイルが下地に使う「最新メッシュ」を永続化する。
            if let landmarks = analysisResult?.landmarksNormalized, !landmarks.isEmpty {
                let w = analysisResult?.imageWidthPx ?? 0
                let h = analysisResult?.imageHeightPx ?? 0
                let aspect = (w > 0 && h > 0) ? CGFloat(w) / CGFloat(h) : 4.0 / 5.0
                LatestFaceMeshStore.save(landmarksNormalized: landmarks, imageAspect: aspect)
            }
        }
    }

    // Studio の化粧状態。化粧単位 (MakeupUnit) ごとに meshID→色 を持つ唯一の真実。
    // 顔判定結果で初期値が決まり、ユーザーが一度でも触ったら以降は上書きしない。
    var composition: MakeupComposition = MakeupComposition()
    var activePresetID: String?
    var isRenderingMakeup: Bool = false

    // makeup_claude のアルゴリズムを移植したエンジン。
    // アプリ全体で 1 つを使い回し、AnalyzingView で初期化 + 顔検出 →
    // Studio でレイヤー強度を変更するたびに `render` を再呼び出しする。
    let makeupEngine: MakeupEngineService = MakeupEngineService()

    private var renderTask: Task<Void, Never>?

    // Archive 「試す」フロー: 保存ルックを別の顔で当てて見る一回限りの体験。
    // Diagnosis 完了時のプリセット既定を当てないために MakeupSession でも持つ。
    var tryingSavedLook: Bool = false

    func reset() {
        capturedImage = nil
        renderedImage = nil
        analysisResult = nil
        composition = MakeupComposition()
        activePresetID = nil
        isRenderingMakeup = false
        tryingSavedLook = false
        renderTask?.cancel()
        renderTask = nil
        Task { await makeupEngine.reset() }
    }

    // 顔診断結果が新しく設定されるたびに、顔型に応じた既定 composition を入れ直す。
    // 解析結果は「撮影 1 回につき 1 度」だけ設定される（Studio 編集中に再設定される
    // 経路は無い）ため、ここで毎回当て直してもユーザー編集を踏み潰さない。むしろ
    // 以前は一度きりのフラグで初期化を抑止しており、reset() が呼ばれない実装と相まって
    // 2 回目以降の撮影で前の顔の composition が残るバグになっていた。
    // Try フロー (Archive 経由) は保存ルックの composition を保ちたいので既定を当てない。
    private func applyPresetDefaultsFromAnalysisIfNeeded() {
        guard let result = analysisResult, !tryingSavedLook else { return }
        composition = MakeupCompositionBuilder.makeDefault(for: result.faceShape)
    }

    // 化粧反映を非同期で要求する。短時間に複数回呼ばれても直近の 1 回だけ実行する。
    func requestMakeupRender() {
        renderTask?.cancel()
        let snapshot = composition
        renderTask = Task { [weak self] in
            guard let self else { return }
            // 連続スライド時に過剰な再計算を抑える
            try? await Task.sleep(for: .milliseconds(80))
            if Task.isCancelled { return }
            self.isRenderingMakeup = true
            defer { self.isRenderingMakeup = false }
            let started = Date()
            do {
                let img = try await self.makeupEngine.render(composition: snapshot)
                if Task.isCancelled { return }
                self.renderedImage = img
                let ms = Int(Date().timeIntervalSince(started) * 1000)
                sessionLog.notice("render: ok in \(ms, privacy: .public)ms")
            } catch {
                sessionLog.error("render: failed — \(String(describing: error), privacy: .public)")
            }
        }
    }
}
