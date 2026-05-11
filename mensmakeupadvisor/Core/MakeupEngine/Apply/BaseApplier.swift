import CoreGraphics
import Foundation

// 1.3 ベース（ファンデーション）
// makeup_claude/loadmap/1-virtual-makeup/1-3-base/main.py の `apply_base` を移植。
//
//   1. 顔メッシュ全体でマスク作成
//   2. distanceTransform で中心ほど濃く
//   3. power(0.3) で輪郭付近のフェードを自然に
//   4. mask 範囲で制限
//   5. Gaussian blur で輪郭を滑らかに
//   6. 通常合成（線形ブレンド）
enum BaseApplier {
    struct Options: Sendable {
        // Python 版は BGR=(170,200,235) で渡している(=肌色 RGB(235,200,170))。
        // Swift では RGB そのままで保持し、Compositing 側で 0-255 → 0-1 へ正規化する。
        var colorRGB: SIMD3<Float> = SIMD3<Float>(235, 200, 170)
        var intensity: Float = 0.30
        var blurScale: Float = 2.5
    }

    static func apply(image: CGImage, faceMesh: FaceMesh, options: Options) -> CGImage? {
        let w = image.width
        let h = image.height
        let allMeshIDs = Array(0..<faceMesh.triangles.count)
        let mask = faceMesh.buildMask(meshIDs: allMeshIDs, width: w, height: h)
        let dist = DistanceTransform.l2(from: mask)
        BufferNormalize.toUnit(dist)
        PowerCurve.apply(dist, exponent: 0.3)
        // mask の範囲内に制限
        let maskF = FloatBuffer.fromMask(mask)
        BufferNormalize.multiply(dist, with: maskF)

        let faceH = max(1.0, hypot(
            faceMesh.landmarksPx[FaceLandmarkID.foreheadTop].x - faceMesh.landmarksPx[FaceLandmarkID.chinBottom].x,
            faceMesh.landmarksPx[FaceLandmarkID.foreheadTop].y - faceMesh.landmarksPx[FaceLandmarkID.chinBottom].y
        ))
        let ksize = Int(Double(faceH) * 0.05 * Double(options.blurScale))
        GaussianBlur.apply(dist, ksize: ksize)

        return Compositing.normal(image: image, mask: dist, color: options.colorRGB, intensity: options.intensity)
    }
}
