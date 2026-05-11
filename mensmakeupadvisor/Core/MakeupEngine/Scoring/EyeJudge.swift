import Foundation

// 2.2.4 目の判定
// makeup_claude/loadmap/2/2.2.4-eye/main.py の `analyze` を移植。
enum EyeJudge {
    struct EyeSide: Sendable {
        var widthPx: Double = 0
        var heightPx: Double = 0
        var ratio: Double = 0          // height / width
        var irisDiameterPx: Double = 0
        var whiteLeftPx: Double = 0
        var blackPx: Double = 0
        var whiteRightPx: Double = 0
        var irisNorm: [Double] = []    // white:black:white (black=1)
        var irisLoss: Double = 0       // 1:2:1 との差
    }

    enum Category: Sendable {
        case bigRound, narrow, balanced
    }

    struct Result: Sendable {
        var right: EyeSide
        var left: EyeSide
        var meanWidthRatio: Double
        var idealRatioLoss: Double
        var symmetryScore: Double      // 0-1
        var eyeToFaceRatio: Double
        var category: Category
    }

    static func analyze(faceMesh: FaceMesh) -> Result {
        let right = measureSide(
            faceMesh: faceMesh,
            outer: FaceLandmarkID.eyeOuterR, inner: FaceLandmarkID.eyeInnerR,
            top: FaceLandmarkID.eyeTopR, bot: FaceLandmarkID.eyeBotR,
            irisIds: FaceLandmarkID.irisR
        )
        let left = measureSide(
            faceMesh: faceMesh,
            outer: FaceLandmarkID.eyeOuterL, inner: FaceLandmarkID.eyeInnerL,
            top: FaceLandmarkID.eyeTopL, bot: FaceLandmarkID.eyeBotL,
            irisIds: FaceLandmarkID.irisL
        )

        let meanRatio = (right.ratio + left.ratio) / 2
        let idealLoss = abs(meanRatio - (1.0 / 3.0))

        func sym(_ a: Double, _ b: Double) -> Double {
            let m = (a + b) / 2
            return 1.0 - (m > 1e-3 ? abs(a - b) / m : 0.0)
        }
        let wSym = sym(right.widthPx, left.widthPx)
        let hSym = sym(right.heightPx, left.heightPx)
        let symmetry = max(0.0, min(1.0, (wSym + hSym) / 2))

        let metrics = FaceMetricsCalculator.measure(faceMesh: faceMesh)
        let meanW = (right.widthPx + left.widthPx) / 2
        let eyeToFace = metrics.faceWidthTemplePx > 1e-3
            ? meanW / metrics.faceWidthTemplePx : 0

        let category: Category
        if meanRatio > 0.40 { category = .bigRound }
        else if meanRatio < 0.28 { category = .narrow }
        else { category = .balanced }

        return Result(
            right: right, left: left,
            meanWidthRatio: meanRatio, idealRatioLoss: idealLoss,
            symmetryScore: symmetry, eyeToFaceRatio: eyeToFace,
            category: category
        )
    }

    private static func measureSide(faceMesh: FaceMesh,
                                    outer: Int, inner: Int, top: Int, bot: Int,
                                    irisIds: [Int]) -> EyeSide {
        var s = EyeSide()
        let po = faceMesh.landmarksPx[outer]
        let pi = faceMesh.landmarksPx[inner]
        let pt = faceMesh.landmarksPx[top]
        let pb = faceMesh.landmarksPx[bot]
        s.widthPx = hypot(Double(po.x - pi.x), Double(po.y - pi.y))
        s.heightPx = hypot(Double(pt.x - pb.x), Double(pt.y - pb.y))
        if s.widthPx > 1e-3 { s.ratio = s.heightPx / s.widthPx }

        let xs = irisIds.compactMap { id -> Double? in
            guard faceMesh.landmarksPx.indices.contains(id) else { return nil }
            return Double(faceMesh.landmarksPx[id].x)
        }
        let irisLeftX = xs.min() ?? 0
        let irisRightX = xs.max() ?? 0
        s.irisDiameterPx = irisRightX - irisLeftX

        let eyeLeftX = min(Double(po.x), Double(pi.x))
        let eyeRightX = max(Double(po.x), Double(pi.x))
        s.whiteLeftPx = max(0, irisLeftX - eyeLeftX)
        s.blackPx = s.irisDiameterPx
        s.whiteRightPx = max(0, eyeRightX - irisRightX)
        if s.blackPx > 1e-3 {
            s.irisNorm = [s.whiteLeftPx / s.blackPx, 1.0, s.whiteRightPx / s.blackPx]
            let target = [0.5, 1.0, 0.5]
            let sq = zip(s.irisNorm, target).map { ($0 - $1) * ($0 - $1) }.reduce(0, +)
            s.irisLoss = sqrt(sq / Double(target.count))
        }
        return s
    }
}
