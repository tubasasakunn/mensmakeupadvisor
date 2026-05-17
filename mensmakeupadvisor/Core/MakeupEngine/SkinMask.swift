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

        // 3. 唇 (赤味で skin と紛らわしい) を多角形マスクで 0 にする。
        // 唇外周ランドマークから作ったポリゴンを少し膨らませて掛ける。
        zeroOutLips(mask: mask, faceMesh: faceMesh)

        return mask
    }

    // 唇のポリゴンを mask 上で 0 に塗りつぶす。
    private nonisolated static func zeroOutLips(mask: FloatBuffer, faceMesh: FaceMesh) {
        let w = mask.width
        let h = mask.height
        // 一時 grayscale CGContext に唇ポリゴンを描いて、その内側ピクセルを mask=0 に
        let lipMaskBuf = MaskBuffer(width: w, height: h)
        guard let ctx = CGContext(
            data: lipMaskBuf.dataPointer, width: w, height: h, bitsPerComponent: 8,
            bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return }
        // CGContext は Y-UP なので CTM を反転して画像座標 (Y-DOWN) で描画
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)
        ctx.setFillColor(gray: 1.0, alpha: 1.0)

        let ids = FaceLandmarkID.lipOuter
        var pts: [CGPoint] = []
        for id in ids where faceMesh.points.indices.contains(id) {
            pts.append(faceMesh.landmark(id, width: w, height: h))
        }
        guard pts.count >= 3 else { return }
        ctx.beginPath()
        ctx.move(to: pts[0])
        for i in 1..<pts.count { ctx.addLine(to: pts[i]) }
        ctx.closePath()
        ctx.fillPath()

        // 唇周辺 (口紅にじみで近接する微妙な領域) も少し dilate して切る
        let lipFloat = FloatBuffer.fromMask(lipMaskBuf)
        // 軽く dilate (顔横幅の 0.5% 程度) — 大きすぎると鼻まで切れる
        let templeR = faceMesh.landmark(FaceLandmarkID.templeR, width: w, height: h)
        let templeL = faceMesh.landmark(FaceLandmarkID.templeL, width: w, height: h)
        let faceWPx = max(1.0, abs(templeR.x - templeL.x))
        let dilateR = max(1, Int(Double(faceWPx) * 0.008))
        Morphology.dilate(lipFloat, radius: dilateR)
        // ぼかして急峻な切り口にしない
        let blurK = max(3, Int(Double(faceWPx) * 0.015))
        GaussianBlur.apply(lipFloat, ksize: blurK)
        // mask = mask * (1 - lipFloat)
        for i in 0..<mask.count {
            mask.pointer[i] *= (1.0 - min(1.0, lipFloat.pointer[i]))
        }
    }
}
