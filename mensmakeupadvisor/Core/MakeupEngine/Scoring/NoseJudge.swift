import CoreGraphics
import Foundation

// 2.2.5 鼻の判定
// makeup_claude/loadmap/2/2.2.5-nose/main.py の `analyze` を移植。
enum NoseJudge {
    enum AngleStatus: Sendable { case ideal, acute, obtuse }
    enum ElineStatus: Sendable { case ideal, lipAhead, lipBehind }

    struct Result: Sendable {
        var noseLengthPx: Double
        var noseWingWidthPx: Double
        var eyeGapPx: Double
        var wingToGapRatio: Double
        var lengthToWingRatio: Double
        var noseLipAngleDeg: Double
        var elineOffsetPx: Double
        var elineNorm: Double
        var wingLoss: Double
        var lengthLoss: Double
        var angleStatus: AngleStatus
        var elineStatus: ElineStatus
        var hitsOutOf4: Int
    }

    static func analyze(faceMesh: FaceMesh) -> Result {
        func p(_ i: Int) -> CGPoint { faceMesh.landmarksPx[i] }
        let noseRoot = p(FaceLandmarkID.noseRoot)
        let noseTip = p(FaceLandmarkID.noseTip)
        let subnasal = p(FaceLandmarkID.subnasal)
        let wingR = p(FaceLandmarkID.noseWingR)
        let wingL = p(FaceLandmarkID.noseWingL)
        let eyeInnerR = p(FaceLandmarkID.eyeInnerR)
        let eyeInnerL = p(FaceLandmarkID.eyeInnerL)
        let upperLip = p(FaceLandmarkID.upperLipTop)
        let chin = p(FaceLandmarkID.chinBottom)

        let noseLength = hypot(Double(noseTip.x - noseRoot.x), Double(noseTip.y - noseRoot.y))
        let wingWidth = hypot(Double(wingR.x - wingL.x), Double(wingR.y - wingL.y))
        let eyeGap = hypot(Double(eyeInnerR.x - eyeInnerL.x), Double(eyeInnerR.y - eyeInnerL.y))
        let wingToGap = eyeGap > 1e-3 ? wingWidth / eyeGap : 0
        let lengthToWing = wingWidth > 1e-3 ? noseLength / wingWidth : 0

        // 鼻唇角
        let v1 = CGPoint(x: noseTip.x - subnasal.x, y: noseTip.y - subnasal.y)
        let v2 = CGPoint(x: upperLip.x - subnasal.x, y: upperLip.y - subnasal.y)
        let n1 = hypot(Double(v1.x), Double(v1.y))
        let n2 = hypot(Double(v2.x), Double(v2.y))
        var noseLipAngle = 0.0
        if n1 > 1e-3, n2 > 1e-3 {
            let dot = Double(v1.x * v2.x + v1.y * v2.y)
            let c = max(-1, min(1, dot / (n1 * n2)))
            noseLipAngle = acos(c) * 180 / .pi
        }

        // E ライン
        let ab = CGPoint(x: chin.x - noseTip.x, y: chin.y - noseTip.y)
        let ap = CGPoint(x: upperLip.x - noseTip.x, y: upperLip.y - noseTip.y)
        let abLen = hypot(Double(ab.x), Double(ab.y))
        var elineOffset = 0.0
        var elineNorm = 0.0
        if abLen > 1e-3 {
            let cross = Double(ab.x * ap.y - ab.y * ap.x)
            elineOffset = cross / abLen
            elineNorm = elineOffset / abLen
        }

        let wingLoss = abs(wingToGap - 1.0)
        let lengthLoss = abs(lengthToWing - 1.5) / 1.5

        let angleStatus: AngleStatus
        switch noseLipAngle {
        case 90...100: angleStatus = .ideal
        case ..<90: angleStatus = .acute
        default: angleStatus = .obtuse
        }

        let faceH = hypot(Double(chin.x - noseTip.x), Double(chin.y - noseTip.y))
        let tol = faceH * 0.03
        let elineStatus: ElineStatus
        if abs(elineOffset) < tol { elineStatus = .ideal }
        else if elineOffset > 0 { elineStatus = .lipAhead }
        else { elineStatus = .lipBehind }

        let okWing = wingLoss < 0.20
        let okLength = lengthLoss < 0.20
        let okAngle = (angleStatus == .ideal)
        let okEline = (elineStatus == .ideal)
        let hits = [okWing, okLength, okAngle, okEline].filter { $0 }.count

        return Result(
            noseLengthPx: noseLength, noseWingWidthPx: wingWidth, eyeGapPx: eyeGap,
            wingToGapRatio: wingToGap, lengthToWingRatio: lengthToWing,
            noseLipAngleDeg: noseLipAngle, elineOffsetPx: elineOffset, elineNorm: elineNorm,
            wingLoss: wingLoss, lengthLoss: lengthLoss,
            angleStatus: angleStatus, elineStatus: elineStatus, hitsOutOf4: hits
        )
    }
}
