import CoreGraphics
import Foundation

// 1.2 シャドウ
// makeup_claude/loadmap/1-virtual-makeup/1-2-shadow/main.py の `apply_shadow` を移植。
//
//   1. メッシュ三角形でマスク作成
//   2. distanceTransform → 反転（外側=輪郭側ほど濃い）
//   3. power(1.5) で内側への減衰を緩やかに
//   4. 2段階 Gaussian blur
//   5. 乗算合成（暗くする）
enum ShadowApplier {
    struct Options: Sendable {
        var meshIDs: [Int]
        var colorRGB: SIMD3<Float> = SIMD3<Float>(90, 68, 50)
        var intensity: Float = 0.25
        var blurScale: Float = 2.5
    }

    static func apply(image: CGImage, faceMesh: FaceMesh, options: Options) -> CGImage? {
        let w = image.width
        let h = image.height
        let mask = faceMesh.buildMask(meshIDs: options.meshIDs, width: w, height: h)
        let dist = DistanceTransform.l2(from: mask)
        BufferNormalize.toUnit(dist)
        let maskF = FloatBuffer.fromMask(mask)
        BufferNormalize.invertWithin(dist, mask: maskF)
        PowerCurve.apply(dist, exponent: 1.5)

        let faceH = max(1.0, hypot(
            faceMesh.landmarksPx[FaceLandmarkID.foreheadTop].x - faceMesh.landmarksPx[FaceLandmarkID.chinBottom].x,
            faceMesh.landmarksPx[FaceLandmarkID.foreheadTop].y - faceMesh.landmarksPx[FaceLandmarkID.chinBottom].y
        ))
        let kInner = Int(Double(faceH) * 0.04 * Double(options.blurScale))
        GaussianBlur.apply(dist, ksize: kInner)
        let kOuter = Int(Double(faceH) * 0.02 * Double(options.blurScale))
        GaussianBlur.apply(dist, ksize: kOuter)

        return Compositing.multiply(image: image, mask: dist, color: options.colorRGB, intensity: options.intensity)
    }
}
