import UIKit

// ミラーモードのライブ合成器。フロントカメラの 1 フレームに対して
// MediaPipe で顔メッシュを検出し、MakeupRenderer で化粧を合成して返す。
//
// FaceMesh は非 Sendable で内部状態 (検出ランドマーク) を持つため、actor に
// 閉じ込めて生成・detect・render を直列化する。これにより @unchecked Sendable
// を使わずに Swift 6 strict concurrency と両立する。重い処理 (detect + render) は
// この actor の executor 上で走り、MainActor をブロックしない。
actor LiveMirrorRenderer {
    private let mesh = FaceMesh(subdivisionLevel: 1)
    private var initialized = false

    // 顔が取れなければ nil。呼び出し側は前回の合成結果を保持し続ける。
    func renderMakeup(on frame: UIImage, composition: MakeupComposition) -> UIImage? {
        if !initialized {
            do {
                try mesh.initialize()
                initialized = true
            } catch {
                return nil
            }
        }
        guard (try? mesh.detect(image: frame)) != nil else { return nil }
        return MakeupRenderer.render(image: frame, faceMesh: mesh, composition: composition)
    }
}
