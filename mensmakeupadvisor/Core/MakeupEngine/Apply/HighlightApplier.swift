import CoreGraphics
import Foundation
import UIKit

// 1.1 ハイライト
// makeup_claude/loadmap/1-virtual-makeup/1-1-highlight/main.py の `apply_highlight` を移植。
//
//   1. メッシュ三角形でマスク作成
//   2. distanceTransform → 中心ほど値が大きい
//   3. power(0.5) で端の減衰を緩やかに
//   4. 2段階 Gaussian blur (内側→外側)
//   5. 加算合成
enum HighlightApplier {
    struct Options: Sendable {
        var meshIDs: [Int]
        var colorRGB: SIMD3<Float> = SIMD3<Float>(255, 255, 255)
        var intensity: Float = 0.12
        var blurScale: Float = 2.0
    }

    nonisolated static func apply(image: CGImage, faceMesh: FaceMesh, options: Options) -> CGImage? {
        let w = image.width
        let h = image.height

        // 1. マスク
        let mask = faceMesh.buildMask(meshIDs: options.meshIDs, width: w, height: h)
        let dist = DistanceTransform.l2(from: mask)

        // 2. 正規化 (max → 1)
        BufferNormalize.toUnit(dist)

        // 3. power(0.5)
        PowerCurve.apply(dist, exponent: 0.5)

        // 4. 2段階ブラー (顔の高さに比例)
        let faceH = max(1.0, hypot(
            faceMesh.landmarksPx[FaceLandmarkID.foreheadTop].x - faceMesh.landmarksPx[FaceLandmarkID.chinBottom].x,
            faceMesh.landmarksPx[FaceLandmarkID.foreheadTop].y - faceMesh.landmarksPx[FaceLandmarkID.chinBottom].y
        ))
        let kInner = Int(Double(faceH) * 0.04 * Double(options.blurScale))
        GaussianBlur.apply(dist, ksize: kInner)
        let kOuter = Int(Double(faceH) * 0.02 * Double(options.blurScale))
        GaussianBlur.apply(dist, ksize: kOuter)

        // 5. 加算合成
        return Compositing.additive(image: image, mask: dist, color: options.colorRGB, intensity: options.intensity)
    }
}
