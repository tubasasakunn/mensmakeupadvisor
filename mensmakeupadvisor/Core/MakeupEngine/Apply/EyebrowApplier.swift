import CoreGraphics
import Foundation
import UIKit

// 1.5 眉メイク
// makeup_claude/loadmap/1-virtual-makeup/1-5-eyebrow/main.py を移植。
//
//   Phase 1: 眉消し
//     - 眉ランドマークから dilated polygon mask 生成
//     - OpenCV inpaint TELEA の代替として、マスク外の周辺ピクセルを Gaussian で
//       拡散させてマスク内に塗り込む簡易フィルを行う
//   Phase 2: 眉描画
//     - eyebrow_shapes.json のトレース形状を左右の anchors にマッピング
//     - 二次 Bezier ベースの輪郭をポリゴンとして塗りつぶし、Gaussian でソフトに合成
nonisolated enum EyebrowApplier {
    nonisolated enum BrowType: String, CaseIterable, Sendable {
        case natural, straight, arch, parallel, corner
    }

    nonisolated struct Options: Sendable {
        var type: BrowType = .straight
        var colorRGB: SIMD3<Float> = SIMD3<Float>(85, 60, 45)
        var intensity: Float = 0.75
        var thicknessScale: Float = 1.0
        var doErase: Bool = true
        var doDraw: Bool = true
    }

    nonisolated static func apply(image: CGImage, faceMesh: FaceMesh, options: Options) -> CGImage? {
        var current = image
        if options.doErase {
            if let erased = eraseEyebrows(image: current, faceMesh: faceMesh) {
                current = erased
            }
        }
        if options.doDraw {
            if let drawn = drawEyebrows(image: current, faceMesh: faceMesh, options: options) {
                current = drawn
            }
        }
        return current
    }

    // MARK: - Erase

    private nonisolated static func buildEyebrowPolygonMask(faceMesh: FaceMesh, width: Int, height: Int,
                                                expandPx: Int = 0) -> MaskBuffer {
        let mask = MaskBuffer(width: width, height: height)
        guard let ctx = CGContext(
            data: mask.dataPointer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return mask }
        ctx.setFillColor(gray: 1.0, alpha: 1.0)

        let pairs: [(upper: [Int], lower: [Int])] = [
            (FaceLandmarkID.rightEyebrowUpper, FaceLandmarkID.rightEyebrowLower),
            (FaceLandmarkID.leftEyebrowUpper, FaceLandmarkID.leftEyebrowLower),
        ]
        for (upper, lower) in pairs {
            var pts: [CGPoint] = []
            for id in upper where faceMesh.landmarksPx.indices.contains(id) {
                pts.append(faceMesh.landmarksPx[id])
            }
            for id in lower.reversed() where faceMesh.landmarksPx.indices.contains(id) {
                pts.append(faceMesh.landmarksPx[id])
            }
            guard pts.count >= 3 else { continue }
            ctx.beginPath()
            ctx.move(to: pts[0])
            for i in 1..<pts.count { ctx.addLine(to: pts[i]) }
            ctx.closePath()
            ctx.fillPath()
        }

        if expandPx > 0 {
            let f = FloatBuffer.fromMask(mask)
            Morphology.dilate(f, radius: expandPx)
            for i in 0..<mask.count {
                mask.pointer[i] = UInt8(min(255, Int(f.pointer[i] * 255)))
            }
        }
        return mask
    }

    private nonisolated static func eraseEyebrows(image: CGImage, faceMesh: FaceMesh) -> CGImage? {
        let w = image.width
        let h = image.height
        let faceH = max(1.0, hypot(
            faceMesh.landmarksPx[FaceLandmarkID.foreheadTop].x - faceMesh.landmarksPx[FaceLandmarkID.chinBottom].x,
            faceMesh.landmarksPx[FaceLandmarkID.foreheadTop].y - faceMesh.landmarksPx[FaceLandmarkID.chinBottom].y
        ))
        let expandPx = max(5, Int(Double(faceH) * 0.025))
        let mask = buildEyebrowPolygonMask(faceMesh: faceMesh, width: w, height: h, expandPx: expandPx)

        // TELEA inpaint の代替: マスク領域の各画素を、その上下に最も近い「マスク外」の
        // 画素色で線形補間して埋める。眉は水平方向に長いので、上下方向の補間が自然。
        let count = w * h * 4
        let bytesPerRow = w * 4
        let info: CGBitmapInfo = [
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            CGBitmapInfo.byteOrder32Big,
        ]
        let srcBuf = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        let outBuf = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        defer { srcBuf.deallocate(); outBuf.deallocate() }
        srcBuf.initialize(repeating: 0, count: count)
        outBuf.initialize(repeating: 0, count: count)

        guard let ctx = CGContext(
            data: srcBuf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info.rawValue
        ) else { return image }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        for i in 0..<count { outBuf[i] = srcBuf[i] }

        for x in 0..<w {
            // 列ごとに、マスク内の連続区間を上下境界色で補間
            var y = 0
            while y < h {
                if mask[x, y] > 0 {
                    let start = y
                    while y < h && mask[x, y] > 0 { y += 1 }
                    let end = y - 1
                    let upY = max(0, start - 1)
                    let dnY = min(h - 1, end + 1)
                    let upIdx = (upY * w + x) * 4
                    let dnIdx = (dnY * w + x) * 4
                    let span = max(1, end - start + 1)
                    for yy in start...end {
                        let t = Double(yy - start + 1) / Double(span + 1)
                        let idx = (yy * w + x) * 4
                        outBuf[idx]     = UInt8(Double(srcBuf[upIdx])     * (1 - t) + Double(srcBuf[dnIdx])     * t)
                        outBuf[idx + 1] = UInt8(Double(srcBuf[upIdx + 1]) * (1 - t) + Double(srcBuf[dnIdx + 1]) * t)
                        outBuf[idx + 2] = UInt8(Double(srcBuf[upIdx + 2]) * (1 - t) + Double(srcBuf[dnIdx + 2]) * t)
                        outBuf[idx + 3] = 255
                    }
                } else {
                    y += 1
                }
            }
        }

        guard let ctx2 = CGContext(
            data: outBuf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info.rawValue
        ) else { return image }
        return ctx2.makeImage()
    }

    // MARK: - Draw

    nonisolated struct Anchors {
        var head: CGPoint
        var tail: CGPoint
        var eyeHeight: Double
        var browLength: Double
    }

    // Python `compute_brow_anchors` の対称化ロジックを忠実に移植。
    private nonisolated static func anchors(faceMesh: FaceMesh, side: Side) -> Anchors {
        struct SideData {
            var noseWing: CGPoint
            var innerEye: CGPoint
            var outerEye: CGPoint
            var eyeTop: CGPoint
            var eyeBot: CGPoint
            var browHead: CGPoint
            var browTail: CGPoint
            var irisCenter: CGPoint
            var eyeHeight: Double
        }
        func load(_ side: Side) -> SideData {
            switch side {
            case .right:
                let irisCenter = FaceMetricsCalculator.mean(faceMesh, ids: FaceLandmarkID.irisR)
                let top = FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.eyeTopR)
                let bot = FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.eyeBotR)
                return SideData(
                    noseWing: FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.noseWingR),
                    innerEye: FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.eyeInnerR),
                    outerEye: FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.eyeOuterR),
                    eyeTop: top, eyeBot: bot,
                    browHead: FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.browHeadR),
                    browTail: FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.browTailR),
                    irisCenter: irisCenter,
                    eyeHeight: abs(Double(top.y - bot.y))
                )
            case .left:
                let irisCenter = FaceMetricsCalculator.mean(faceMesh, ids: FaceLandmarkID.irisL)
                let top = FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.eyeTopL)
                let bot = FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.eyeBotL)
                return SideData(
                    noseWing: FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.noseWingL),
                    innerEye: FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.eyeInnerL),
                    outerEye: FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.eyeOuterL),
                    eyeTop: top, eyeBot: bot,
                    browHead: FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.browHeadL),
                    browTail: FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.browTailL),
                    irisCenter: irisCenter,
                    eyeHeight: abs(Double(top.y - bot.y))
                )
            }
        }
        let r = load(.right)
        let l = load(.left)
        let faceCx = Double(FaceMetricsCalculator.p(faceMesh, FaceLandmarkID.noseTip).x)
        let avgEyeHeight = (r.eyeHeight + l.eyeHeight) / 2
        let avgEyeTopY = (Double(r.eyeTop.y) + Double(l.eyeTop.y)) / 2
        let headY = avgEyeTopY - avgEyeHeight * 1.85

        let rHeadOff = abs(Double(r.browHead.x) - faceCx)
        let lHeadOff = abs(Double(l.browHead.x) - faceCx)
        let avgHeadOff = (rHeadOff + lHeadOff) / 2

        func tailOffset(_ sd: SideData) -> Double {
            let nose = sd.noseWing
            let eye = sd.outerEye
            let dx = Double(eye.x - nose.x)
            let dy = Double(eye.y - nose.y)
            let goldenX: Double
            if abs(dy) < 1e-3 {
                goldenX = Double(eye.x) + (Double(eye.x) - Double(sd.innerEye.x)) * 0.3
            } else {
                let t = (headY - Double(nose.y)) / dy
                goldenX = Double(nose.x) + t * dx
            }
            return max(abs(goldenX - faceCx), abs(Double(sd.browTail.x) - faceCx))
        }
        let rTailOff = tailOffset(r)
        let lTailOff = tailOffset(l)
        let avgTailOff = (rTailOff + lTailOff) / 2

        let headX: Double
        let tailX: Double
        switch side {
        case .right:
            headX = faceCx - avgHeadOff
            tailX = faceCx - avgTailOff
        case .left:
            headX = faceCx + avgHeadOff
            tailX = faceCx + avgTailOff
        }

        return Anchors(
            head: CGPoint(x: headX, y: headY),
            tail: CGPoint(x: tailX, y: headY),
            eyeHeight: avgEyeHeight,
            browLength: abs(tailX - headX)
        )
    }

    nonisolated enum Side { case right, left }

    // eyebrow_shapes.json をキャッシュ
    nonisolated(unsafe) private static var shapesCache: [String: (upper: [(Double, Double)], lower: [(Double, Double)])] = [:]

    private nonisolated static func loadShapes() {
        guard shapesCache.isEmpty else { return }
        guard let url = Bundle.main.url(forResource: "eyebrow_shapes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: [[Double]]]]
        else { return }
        for (k, v) in json {
            let upper = (v["upper"] ?? []).compactMap { p -> (Double, Double)? in
                p.count == 2 ? (p[0], p[1]) : nil
            }
            let lower = (v["lower"] ?? []).compactMap { p -> (Double, Double)? in
                p.count == 2 ? (p[0], p[1]) : nil
            }
            shapesCache[k] = (upper, lower)
        }
    }

    // shape (正規化 t/offset) → ピクセル座標のポリゴン
    private nonisolated static func polygonFromShape(anchors: Anchors,
                                         shape: (upper: [(Double, Double)], lower: [(Double, Double)]),
                                         thicknessScale: Double = 1.0,
                                         samples: Int = 80) -> [CGPoint] {
        let head = SIMD2<Double>(Double(anchors.head.x), Double(anchors.head.y))
        let tail = SIMD2<Double>(Double(anchors.tail.x), Double(anchors.tail.y))
        var axis = tail - head
        let axisLen = (axis.x * axis.x + axis.y * axis.y).squareRoot()
        guard axisLen > 1e-3 else { return [] }
        axis = axis / axisLen
        // 上向き法線（画像座標で y は下向きなので、negative y を選ぶ）
        var normal = SIMD2<Double>(axis.y, -axis.x)
        if normal.y > 0 { normal = -normal }

        func interp(_ pts: [(Double, Double)], n: Int) -> [(Double, Double)] {
            guard !pts.isEmpty else { return [] }
            let sorted = pts.sorted { $0.0 < $1.0 }
            let ts = sorted.map { $0.0 }
            let offs = sorted.map { $0.1 }
            let tMin = ts[0]
            let tMax = ts[ts.count - 1]
            var out: [(Double, Double)] = []
            for i in 0..<n {
                let t = tMin + (tMax - tMin) * Double(i) / Double(n - 1)
                // 線形補間
                var lo = 0
                var hi = ts.count - 1
                for j in 0..<(ts.count - 1) where ts[j] <= t && t <= ts[j + 1] {
                    lo = j; hi = j + 1; break
                }
                let span = max(1e-9, ts[hi] - ts[lo])
                let r = (t - ts[lo]) / span
                let o = offs[lo] * (1 - r) + offs[hi] * r
                out.append((t, o))
            }
            return out
        }
        var upperInt = interp(shape.upper, n: samples)
        var lowerInt = interp(shape.lower, n: samples)

        // thickness 拡大
        if abs(thicknessScale - 1.0) > 1e-3 {
            for i in 0..<samples {
                let center = (upperInt[i].1 + lowerInt[i].1) / 2
                let halfThick = (upperInt[i].1 - lowerInt[i].1) / 2
                upperInt[i].1 = center + halfThick * thicknessScale
                lowerInt[i].1 = center - halfThick * thicknessScale
            }
        }

        func toWorld(_ p: (Double, Double)) -> CGPoint {
            let pos = head + axis * (p.0 * axisLen) + normal * (p.1 * axisLen)
            return CGPoint(x: pos.x, y: pos.y)
        }
        var poly: [CGPoint] = upperInt.map(toWorld)
        poly.append(contentsOf: lowerInt.reversed().map(toWorld))
        return poly
    }

    private nonisolated static func drawEyebrows(image: CGImage, faceMesh: FaceMesh, options: Options) -> CGImage? {
        loadShapes()
        guard let shape = shapesCache[options.type.rawValue] else { return image }

        let w = image.width
        let h = image.height
        let mask = MaskBuffer(width: w, height: h)
        guard let ctx = CGContext(
            data: mask.dataPointer, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return image }
        ctx.setFillColor(gray: 1.0, alpha: 1.0)

        for side in [Side.right, .left] {
            let a = anchors(faceMesh: faceMesh, side: side)
            let poly = polygonFromShape(anchors: a, shape: shape,
                                        thicknessScale: Double(options.thicknessScale))
            guard poly.count >= 3 else { continue }
            ctx.beginPath()
            ctx.move(to: poly[0])
            for i in 1..<poly.count { ctx.addLine(to: poly[i]) }
            ctx.closePath()
            ctx.fillPath()
        }

        let soft = FloatBuffer.fromMask(mask)
        let faceH = max(1.0, hypot(
            faceMesh.landmarksPx[FaceLandmarkID.foreheadTop].x - faceMesh.landmarksPx[FaceLandmarkID.chinBottom].x,
            faceMesh.landmarksPx[FaceLandmarkID.foreheadTop].y - faceMesh.landmarksPx[FaceLandmarkID.chinBottom].y
        ))
        let ksize = max(3, Int(Double(faceH) * 0.005))
        GaussianBlur.apply(soft, ksize: ksize)
        return Compositing.normal(image: image, mask: soft, color: options.colorRGB, intensity: options.intensity)
    }
}
