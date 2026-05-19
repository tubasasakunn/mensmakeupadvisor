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
nonisolated enum ShadowApplier {
    nonisolated struct Options: Sendable {
        var meshIDs: [Int]
        var colorRGB: SIMD3<Float> = SIMD3<Float>(90, 68, 50)
        var intensity: Float = 0.25
        // シャドウ領域 (こめかみ/エラ/フェイスライン) は輪郭沿いの細い帯。
        // 2.5 では 2 段ブラーのカーネルが顔の高さの 10% に達し、細い帯が
        // 拡散しきって効果がほぼ消える。highlight (blobby・2.0) より細い帯を
        // 扱うため、より小さい値で「柔らかいが視認できる」状態にする。
        var blurScale: Float = 1.4
    }

    nonisolated static func apply(image: CGImage, faceMesh: FaceMesh, options: Options,
                       skinMask: FloatBuffer? = nil) -> CGImage? {
        let w = image.width
        let h = image.height
        let mask = faceMesh.buildMask(meshIDs: options.meshIDs, width: w, height: h)
        let dist = DistanceTransform.l2(from: mask)
        BufferNormalize.toUnit(dist)
        let maskF = FloatBuffer.fromMask(mask)
        BufferNormalize.invertWithin(dist, mask: maskF)
        PowerCurve.apply(dist, exponent: 1.5)

        let top = faceMesh.landmark(FaceLandmarkID.foreheadTop, width: w, height: h)
        let chin = faceMesh.landmark(FaceLandmarkID.chinBottom, width: w, height: h)
        let faceH = max(1.0, hypot(top.x - chin.x, top.y - chin.y))
        let kInner = Int(Double(faceH) * 0.04 * Double(options.blurScale))
        GaussianBlur.apply(dist, ksize: kInner)
        let kOuter = Int(Double(faceH) * 0.02 * Double(options.blurScale))
        GaussianBlur.apply(dist, ksize: kOuter)
        // POC (apply_shadow) は blur 後に再クランプしない。Swift で押し戻すと
        // 輪郭が硬くなりブラー感が失われるためここでは行わない。

        // 肌マスクで髪・眉・口・目を除外
        if let skinMask, skinMask.width == w, skinMask.height == h {
            BufferNormalize.multiply(dist, with: skinMask)
        }

        return Compositing.multiply(image: image, mask: dist, color: options.colorRGB, intensity: options.intensity)
    }
}
