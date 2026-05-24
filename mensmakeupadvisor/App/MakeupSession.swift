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
    private var presetsInitializedFromAnalysis = false

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
        presetsInitializedFromAnalysis = false
        renderTask?.cancel()
        renderTask = nil
        Task { await makeupEngine.reset() }
    }

    // 顔診断完了時、ユーザーがまだ化粧を触っていなければ顔型に応じた
    // 既定 composition を入れる。一度でも触ったら以降は上書きしない。
    // Try フロー (Archive 経由) は保存ルックの composition を保ちたいので既定を当てない。
    private func applyPresetDefaultsFromAnalysisIfNeeded() {
        guard !presetsInitializedFromAnalysis else { return }
        guard !tryingSavedLook else {
            presetsInitializedFromAnalysis = analysisResult != nil
            return
        }
        composition = MakeupCompositionBuilder.makeDefault(for: analysisResult?.faceShape)
        presetsInitializedFromAnalysis = analysisResult != nil
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
