import CoreGraphics
import Foundation

// 肌の色をサンプリングして「肌っぽさ」マスクを作る。
//
// ベース/ハイライト/シャドウは顔メッシュ全体や三角形領域を使うため、
// 髪の毛が額にかかっていたり、眉/口/目の上にメッシュ範囲が乗ったりすると
// そこにも化粧色がついてしまう。MediaPipe FaceMesh だけでは「メッシュの中の
// 何が肌で何がそれ以外か」を区別できないので、画像のピクセル色を見て
// 肌色から大きく外れる場所を soft mask で 0 にする。
//
// アルゴリズム:
//   1. 頬骨・鼻・顎下などの "ほぼ確実に肌" のランドマーク周辺 5x5 をサンプル
//   2. その RGB 平均を肌色とみなす
//   3. 各ピクセルについて肌色との RGB ユークリッド距離 (0-1) を計算
//   4. 距離が threshold 以下なら 1、超えたら 0 にフェード (soft mask)
//
// このマスクを各 Applier の dist に掛け合わせると、肌以外 (髪/眉/唇/目) は
// 化粧反映を実質スキップできる。
nonisolated enum SkinMask {
    // 距離 0..threshold が 1..0 にマップされる。0.30 は RGB 0-1 空間で
    // 「肌色と明らかに違う色」(=髪・眉・唇・目) を切れる、かつ肌のハイライト/
    // シャドウのバリエーションは残せる値として経験的に選択。
    nonisolated static let defaultThreshold: Float = 0.30

    // 肌サンプルに使うランドマーク (頬骨・鼻・顎下・人中下 etc)。
    // 髪やヒゲがかかる確率が低い場所だけを選ぶ。
    private nonisolated static let skinSampleLandmarks: [Int] = [
        FaceLandmarkID.cheekboneR, FaceLandmarkID.cheekboneL,
        FaceLandmarkID.noseRoot, FaceLandmarkID.noseTip, FaceLandmarkID.subnasal,
        FaceLandmarkID.lowerJawR, FaceLandmarkID.lowerJawL,
    ]

    nonisolated static func build(image: CGImage, faceMesh: FaceMesh,
                                  threshold: Float = defaultThreshold,
                                  feather: Float = 0.05) -> FloatBuffer? {
        let w = image.width
        let h = image.height
        let bytesPerRow = w * 4
        let info: CGBitmapInfo = [
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            CGBitmapInfo.byteOrder32Big,
        ]
        let pixelCount = w * h * 4
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: pixelCount)
        defer { buffer.deallocate() }
        buffer.initialize(repeating: 0, count: pixelCount)
        guard let ctx = CGContext(
            data: buffer, width: w, height: h, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info.rawValue
        ) else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

        // 1. 各ランドマーク周辺の 5x5 patch を集めて RGB 平均を取る
        var sumR = 0.0, sumG = 0.0, sumB = 0.0, cnt = 0
        for id in skinSampleLandmarks {
            let p = faceMesh.landmark(id, width: w, height: h)
            let cx = Int(p.x.rounded())
            let cy = Int(p.y.rounded())
            for dy in -2...2 {
                let yy = cy + dy
                if yy < 0 || yy >= h { continue }
                for dx in -2...2 {
                    let xx = cx + dx
                    if xx < 0 || xx >= w { continue }
                    let idx = (yy * w + xx) * 4
                    sumR += Double(buffer[idx])
                    sumG += Double(buffer[idx + 1])
                    sumB += Double(buffer[idx + 2])
                    cnt += 1
                }
            }
        }
        guard cnt > 0 else { return nil }
        let nF = Float(cnt)
        let skinR = Float(sumR) / nF / 255.0
        let skinG = Float(sumG) / nF / 255.0
        let skinB = Float(sumB) / nF / 255.0

        // 2. 全ピクセルで肌色との距離 → soft mask
        let mask = FloatBuffer(width: w, height: h)
        let edge0 = max(0.001, threshold - feather)   // 完全に 1
        let edge1 = threshold + feather               // 完全に 0
        let inv = 1.0 / max(1e-6, edge1 - edge0)
        for y in 0..<h {
            for x in 0..<w {
                let idx = (y * w + x) * 4
                let r = Float(buffer[idx]) / 255.0
                let g = Float(buffer[idx + 1]) / 255.0
                let b = Float(buffer[idx + 2]) / 255.0
                let dr = r - skinR, dg = g - skinG, db = b - skinB
                let dist = (dr * dr + dg * dg + db * db).squareRoot()
                // smoothstep
                let t = max(0.0, min(1.0, (dist - edge0) * inv))
                mask.pointer[y * w + x] = 1.0 - t
            }
        }
        return mask
    }
}
