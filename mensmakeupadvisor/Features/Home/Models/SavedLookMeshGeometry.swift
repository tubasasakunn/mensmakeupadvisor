import CoreGraphics
import Foundation

// Archive のサムネイルが化粧を「実際の mesh ID」で描くための下地。
// 直近診断の 478 ランドマークから細分化メッシュ (頂点 + 三角形) を復元して保持する。
// 三角形の index は target.json の mesh ID と一致する。
struct SavedLookMeshGeometry {
    let points: [CGPoint]                 // 細分化後の頂点 (0-1 正規化座標)
    let triangles: [(Int, Int, Int)]      // 細分化後の三角形 (頂点 index)
    let imageAspect: CGFloat              // 撮影画像の幅 / 高さ

    static func makeLatest() -> SavedLookMeshGeometry? {
        guard let stored = LatestFaceMeshStore.load(),
              let geo = FaceMesh().buildGeometry(fromNormalizedLandmarks: stored.landmarks) else {
            return nil
        }
        return SavedLookMeshGeometry(
            points: geo.points.map { CGPoint(x: $0.x, y: $0.y) },
            triangles: geo.triangles,
            imageAspect: stored.imageAspect
        )
    }
}
