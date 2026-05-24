import CoreGraphics
import Foundation

// 直近の顔診断で取得した 478 点 facemesh を永続化する。
// アーカイブのサムネイルは「最新メッシュ」を下地にするため、アプリ再起動後も
// 参照できるよう UserDefaults に保存しておく。
enum LatestFaceMeshStore {
    private static let landmarksKey = "latest_face_mesh_v1"
    private static let aspectKey = "latest_face_mesh_aspect_v1"

    struct Stored: Sendable {
        // 撮影画像に対する 0-1 正規化座標 (478 点)。x は画像幅、y は画像高さで
        // 個別に正規化されているため、そのまま正方形に描くと顔が歪む。
        let landmarks: [CGPoint]
        // 撮影画像の幅 / 高さ。サムネイルで正規化座標の歪みを補正するのに使う。
        let imageAspect: CGFloat
    }

    static func save(landmarksNormalized: [CGPoint], imageAspect: CGFloat) {
        guard landmarksNormalized.count >= 468 else { return }
        let flat = landmarksNormalized.flatMap { [Double($0.x), Double($0.y)] }
        UserDefaults.standard.set(flat, forKey: landmarksKey)
        UserDefaults.standard.set(Double(imageAspect), forKey: aspectKey)
    }

    static func load() -> Stored? {
        guard let flat = UserDefaults.standard.array(forKey: landmarksKey) as? [Double],
              flat.count >= 936, flat.count.isMultiple(of: 2) else { return nil }
        let landmarks = stride(from: 0, to: flat.count, by: 2).map { i in
            CGPoint(x: flat[i], y: flat[i + 1])
        }
        // aspect 未保存の旧データは縦長 4:5 を既定にする。
        let stored = UserDefaults.standard.object(forKey: aspectKey) as? Double
        let aspect = stored.map { CGFloat($0) } ?? (4.0 / 5.0)
        return Stored(landmarks: landmarks, imageAspect: aspect > 0 ? aspect : 4.0 / 5.0)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: landmarksKey)
        UserDefaults.standard.removeObject(forKey: aspectKey)
    }
}
