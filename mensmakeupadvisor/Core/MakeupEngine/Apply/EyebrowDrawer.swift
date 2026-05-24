import CoreGraphics
import Foundation

// eyebrow_shapes.json のトレース形状を左右の anchors にマッピングし、
// 二次曲線ベースのポリゴンとして塗りつぶし → Gaussian でソフト合成する。
nonisolated enum EyebrowDrawer {
    nonisolated static func draw(image: CGImage, faceMesh: FaceMesh,
                                 options: EyebrowApplier.Options) -> CGImage? {
        guard let shape = shapesCache[options.type.rawValue] else { return image }

        let w = image.width
        let h = image.height
        let mask = MaskBuffer(width: w, height: h)
        guard let ctx = CGContext(
            data: mask.dataPointer, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return image }
        // anchors / polygonFromShape は画像座標(Y-DOWN)で計算しているため CTM を反転。
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)
        ctx.setFillColor(gray: 1.0, alpha: 1.0)

        for side in [Side.right, .left] {
            let a = anchors(faceMesh: faceMesh, side: side, width: w, height: h)
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
        let top = faceMesh.landmark(FaceLandmarkID.foreheadTop, width: w, height: h)
        let chin = faceMesh.landmark(FaceLandmarkID.chinBottom, width: w, height: h)
        let faceH = max(1.0, hypot(top.x - chin.x, top.y - chin.y))
        let ksize = max(3, Int(Double(faceH) * 0.005))
        GaussianBlur.apply(soft, ksize: ksize)
        return Compositing.normal(image: image, mask: soft, color: options.colorRGB, intensity: options.intensity)
    }

    // MARK: - Anchors

    private nonisolated enum Side { case right, left }

    private nonisolated struct Anchors {
        var head: CGPoint
        var tail: CGPoint
        var eyeHeight: Double
        var browLength: Double
    }

    private nonisolated static func lm(_ fm: FaceMesh, _ id: Int, _ width: Int, _ height: Int) -> CGPoint {
        fm.landmark(id, width: width, height: height)
    }

    private nonisolated static func meanLm(_ fm: FaceMesh, ids: [Int], width: Int, height: Int) -> CGPoint {
        guard !ids.isEmpty else { return .zero }
        var sx = 0.0, sy = 0.0, cnt = 0
        for i in ids where fm.points.indices.contains(i) {
            let p = fm.landmark(i, width: width, height: height)
            sx += Double(p.x); sy += Double(p.y); cnt += 1
        }
        guard cnt > 0 else { return .zero }
        return CGPoint(x: sx / Double(cnt), y: sy / Double(cnt))
    }

    // Python `compute_brow_anchors` の対称化ロジックを忠実に移植。
    private nonisolated static func anchors(faceMesh: FaceMesh, side: Side,
                                            width: Int, height: Int) -> Anchors {
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
                let irisCenter = meanLm(faceMesh, ids: FaceLandmarkID.irisR, width: width, height: height)
                let top = lm(faceMesh, FaceLandmarkID.eyeTopR, width, height)
                let bot = lm(faceMesh, FaceLandmarkID.eyeBotR, width, height)
                return SideData(
                    noseWing: lm(faceMesh, FaceLandmarkID.noseWingR, width, height),
                    innerEye: lm(faceMesh, FaceLandmarkID.eyeInnerR, width, height),
                    outerEye: lm(faceMesh, FaceLandmarkID.eyeOuterR, width, height),
                    eyeTop: top, eyeBot: bot,
                    browHead: lm(faceMesh, FaceLandmarkID.browHeadR, width, height),
                    browTail: lm(faceMesh, FaceLandmarkID.browTailR, width, height),
                    irisCenter: irisCenter,
                    eyeHeight: abs(Double(top.y - bot.y))
                )
            case .left:
                let irisCenter = meanLm(faceMesh, ids: FaceLandmarkID.irisL, width: width, height: height)
                let top = lm(faceMesh, FaceLandmarkID.eyeTopL, width, height)
                let bot = lm(faceMesh, FaceLandmarkID.eyeBotL, width, height)
                return SideData(
                    noseWing: lm(faceMesh, FaceLandmarkID.noseWingL, width, height),
                    innerEye: lm(faceMesh, FaceLandmarkID.eyeInnerL, width, height),
                    outerEye: lm(faceMesh, FaceLandmarkID.eyeOuterL, width, height),
                    eyeTop: top, eyeBot: bot,
                    browHead: lm(faceMesh, FaceLandmarkID.browHeadL, width, height),
                    browTail: lm(faceMesh, FaceLandmarkID.browTailL, width, height),
                    irisCenter: irisCenter,
                    eyeHeight: abs(Double(top.y - bot.y))
                )
            }
        }
        let r = load(.right)
        let l = load(.left)
        let faceCx = Double(lm(faceMesh, FaceLandmarkID.noseTip, width, height).x)
        let avgEyeHeight = (r.eyeHeight + l.eyeHeight) / 2

        // 眉の Y 位置は被写体ごとに 眉と目の距離が違うので「実際の眉ランドマークの
        // 下辺の平均 Y」を採用する。検出された眉のすぐ上に揃って描画される。
        let lowerBrowIDs: [Int] = FaceLandmarkID.rightEyebrowLower + FaceLandmarkID.leftEyebrowLower
        let validLower = lowerBrowIDs.filter { faceMesh.points.indices.contains($0) }
        let headY: Double
        if !validLower.isEmpty {
            let ySum = validLower
                .map { Double(faceMesh.landmark($0, width: width, height: height).y) }
                .reduce(0, +)
            headY = ySum / Double(validLower.count)
        } else {
            // フォールバック (ランドマーク欠落時): POC と同じ式
            let avgEyeTopY = (Double(r.eyeTop.y) + Double(l.eyeTop.y)) / 2
            headY = avgEyeTopY - avgEyeHeight * 1.85
        }

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

    // MARK: - Shape

    // static let は Swift ランタイムが 1 回限りスレッドセーフに初期化するので
    // 別途ロックも nonisolated(unsafe) も不要。JSON が無い／壊れている場合は空辞書。
    private static let shapesCache: [String: (upper: [(Double, Double)], lower: [(Double, Double)])] = {
        guard let url = Bundle.main.url(forResource: "eyebrow_shapes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: [[Double]]]]
        else { return [:] }
        var result: [String: (upper: [(Double, Double)], lower: [(Double, Double)])] = [:]
        for (k, v) in json {
            let upper = (v["upper"] ?? []).compactMap { p -> (Double, Double)? in
                p.count == 2 ? (p[0], p[1]) : nil
            }
            let lower = (v["lower"] ?? []).compactMap { p -> (Double, Double)? in
                p.count == 2 ? (p[0], p[1]) : nil
            }
            result[k] = (upper, lower)
        }
        return result
    }()

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
        // 画像座標で y は下向きなので、negative y を選ぶ
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
}
