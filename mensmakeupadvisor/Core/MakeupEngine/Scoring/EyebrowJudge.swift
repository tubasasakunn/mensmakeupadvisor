import Foundation

// 2.2.7 眉の幾何学的判定 (一直線ルール)
// makeup_claude/loadmap/2/2.2.7-eyebrow/main.py の `analyze` を移植。
enum EyebrowJudge {
    struct BrowSide: Sendable {
        var head: CGPoint = .zero
        var peak: CGPoint = .zero
        var tail: CGPoint = .zero

        var headDeviationPx: Double = 0
        var tailDeviationPx: Double = 0
        var peakDeviationPx: Double = 0

        var headToPeakPx: Double = 0
        var peakToTailPx: Double = 0
        var peakRatio: Double = 0  // 理想 2.0

        var horizontalTiltDeg: Double = 0
        var angleHeadToPeakDeg: Double = 0  // 上向き正
    }

    enum Category: Sendable {
        case masculineRising
        case natural
        case flatParallel
    }

    struct Result: Sendable {
        var right: BrowSide
        var left: BrowSide
        var symmetryScore: Double
        var category: Category
    }

    private static func signedDistance(_ a: CGPoint, _ b: CGPoint, _ pt: CGPoint) -> Double {
        let abx = Double(b.x - a.x)
        let aby = Double(b.y - a.y)
        let apx = Double(pt.x - a.x)
        let apy = Double(pt.y - a.y)
        let denom = hypot(abx, aby)
        if denom < 1e-6 { return 0 }
        return (abx * apy - aby * apx) / denom
    }

    private static func measureSide(faceMesh: FaceMesh,
                                    headId: Int, peakId: Int, tailId: Int,
                                    eyeInId: Int, eyeOutId: Int,
                                    irisOuterId: Int, noseWingId: Int) -> BrowSide {
        var s = BrowSide()
        s.head = faceMesh.landmarksPx[headId]
        s.peak = faceMesh.landmarksPx[peakId]
        s.tail = faceMesh.landmarksPx[tailId]
        let eyeIn = faceMesh.landmarksPx[eyeInId]
        let eyeOut = faceMesh.landmarksPx[eyeOutId]
        let iris = faceMesh.landmarksPx[irisOuterId]
        let nose = faceMesh.landmarksPx[noseWingId]

        s.headDeviationPx = abs(Double(s.head.x - eyeIn.x))
        s.peakDeviationPx = abs(signedDistance(nose, iris, s.peak))
        s.tailDeviationPx = abs(signedDistance(nose, eyeOut, s.tail))

        s.headToPeakPx = hypot(Double(s.peak.x - s.head.x), Double(s.peak.y - s.head.y))
        s.peakToTailPx = hypot(Double(s.tail.x - s.peak.x), Double(s.tail.y - s.peak.y))
        if s.peakToTailPx > 1e-3 {
            s.peakRatio = s.headToPeakPx / s.peakToTailPx
        }

        let dx = Double(s.tail.x - s.head.x)
        let dy = Double(s.tail.y - s.head.y)
        let length = max(hypot(dx, dy), 1e-6)
        s.horizontalTiltDeg = asin(dy / length) * 180 / .pi
        let dx2 = Double(s.peak.x - s.head.x)
        let dy2 = Double(s.peak.y - s.head.y)
        let len2 = max(hypot(dx2, dy2), 1e-6)
        s.angleHeadToPeakDeg = -asin(dy2 / len2) * 180 / .pi
        return s
    }

    static func analyze(faceMesh: FaceMesh) -> Result {
        let right = measureSide(
            faceMesh: faceMesh,
            headId: FaceLandmarkID.browHeadR, peakId: FaceLandmarkID.browPeakR, tailId: FaceLandmarkID.browTailR,
            eyeInId: FaceLandmarkID.eyeInnerR, eyeOutId: FaceLandmarkID.eyeOuterR,
            irisOuterId: FaceLandmarkID.irisR[3], noseWingId: FaceLandmarkID.noseWingR
        )
        let left = measureSide(
            faceMesh: faceMesh,
            headId: FaceLandmarkID.browHeadL, peakId: FaceLandmarkID.browPeakL, tailId: FaceLandmarkID.browTailL,
            eyeInId: FaceLandmarkID.eyeInnerL, eyeOutId: FaceLandmarkID.eyeOuterL,
            irisOuterId: FaceLandmarkID.irisL[3], noseWingId: FaceLandmarkID.noseWingL
        )
        func sym(_ a: Double, _ b: Double) -> Double {
            let m = (a + b) / 2
            return 1.0 - (m > 1e-3 ? abs(a - b) / m : 0.0)
        }
        let sims = [
            sym(right.headToPeakPx, left.headToPeakPx),
            sym(right.peakToTailPx, left.peakToTailPx),
            sym(abs(right.horizontalTiltDeg), abs(left.horizontalTiltDeg)),
        ]
        let symmetry = max(0.0, min(1.0, sims.reduce(0, +) / Double(sims.count)))

        let avgPeakAngle = (right.angleHeadToPeakDeg + left.angleHeadToPeakDeg) / 2
        let category: Category
        if avgPeakAngle >= 8 { category = .masculineRising }
        else if avgPeakAngle >= 3 { category = .natural }
        else { category = .flatParallel }

        return Result(right: right, left: left, symmetryScore: symmetry, category: category)
    }
}
