import CoreGraphics
import Foundation

// 直近の顔診断で取得した 478 点 facemesh を永続化する。
// アーカイブのサムネイルは「最新メッシュ」を下地にするため、アプリ再起動後も
// 参照できるよう UserDefaults に保存しておく。
enum LatestFaceMeshStore {
    private static let key = "latest_face_mesh_v1"

    // 撮影画像に対する 0-1 正規化座標の配列をフラット化して保存する。
    static func save(landmarksNormalized: [CGPoint]) {
        guard landmarksNormalized.count >= 468 else { return }
        let flat = landmarksNormalized.flatMap { [Double($0.x), Double($0.y)] }
        UserDefaults.standard.set(flat, forKey: key)
    }

    static func load() -> [CGPoint]? {
        guard let flat = UserDefaults.standard.array(forKey: key) as? [Double],
              flat.count >= 936, flat.count.isMultiple(of: 2) else { return nil }
        return stride(from: 0, to: flat.count, by: 2).map { i in
            CGPoint(x: flat[i], y: flat[i + 1])
        }
    }
}
