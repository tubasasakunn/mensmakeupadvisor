import CoreGraphics
import Foundation

// 2.2.6 口の判定
// makeup_claude/loadmap/2/2.2.6-mouth/main.py の `analyze` を移植。
nonisolated enum MouthJudge {
    nonisolated enum LipStatus: Sendable { case ideal, upperHeavy, lowerHeavy }
    nonisolated enum PhiltrumStatus: Sendable { case ideal, philtrumLong, chinLong }
    nonisolated enum AlignmentStatus: Sendable { case ideal, off }

    nonisolated struct Result: Sendable {
        var mouthWidthPx: Double
        var upperLipThicknessPx: Double
        var lowerLipThicknessPx: Double
        var lipRatio: Double
        var philtrumTopPx: Double
        var philtrumBotPx: Double
        var philtrumRatio: Double
        var irisEdgeAlignPx: Double
        var mouthToFaceRatio: Double
        var lipStatus: LipStatus
        var philtrumStatus: PhiltrumStatus
        var alignmentStatus: AlignmentStatus
        var hitsOutOf3: Int
    }

    nonisolated static func analyze(faceMesh: FaceMesh) -> Result {
        func p(_ i: Int) -> CGPoint { faceMesh.landmarksPx[i] }
        let mR = p(FaceLandmarkID.mouthR)
        let mL = p(FaceLandmarkID.mouthL)
        let uOut = p(FaceLandmarkID.upperLipTop)
        let uIn = p(FaceLandmarkID.upperLipIn)
        let lIn = p(FaceLandmarkID.lowerLipIn)
        let lOut = p(FaceLandmarkID.lowerLipBot)
        let subnasal = p(FaceLandmarkID.subnasal)
        let chin = p(FaceLandmarkID.chinBottom)
        let irisR = FaceMetricsCalculator.mean(faceMesh, ids: FaceLandmarkID.irisR)
        let irisL = FaceMetricsCalculator.mean(faceMesh, ids: FaceLandmarkID.irisL)
        let templeR = p(FaceLandmarkID.templeR)
        let templeL = p(FaceLandmarkID.templeL)

        let mouthW = hypot(Double(mR.x - mL.x), Double(mR.y - mL.y))
        let upper = hypot(Double(uOut.x - uIn.x), Double(uOut.y - uIn.y))
        let lower = hypot(Double(lIn.x - lOut.x), Double(lIn.y - lOut.y))
        let lipRatio = upper > 1e-3 ? lower / upper : 0

        let mouthMidY = (Double(uOut.y) + Double(lOut.y)) / 2
        let philtrumTop = mouthMidY - Double(subnasal.y)
        let philtrumBot = Double(chin.y) - mouthMidY
        let philtrumRatio = philtrumTop > 1e-3 ? philtrumBot / philtrumTop : 0

        let diffR = Double(mR.x) - Double(irisR.x)
        let diffL = Double(mL.x) - Double(irisL.x)
        let alignPx = (abs(diffR) + abs(diffL)) / 2

        let faceW = hypot(Double(templeR.x - templeL.x), Double(templeR.y - templeL.y))
        let mouthToFace = faceW > 1e-3 ? mouthW / faceW : 0

        let lipStatus: LipStatus
        if (1.2...2.2).contains(lipRatio) { lipStatus = .ideal }
        else if lipRatio < 1.2 { lipStatus = .upperHeavy }
        else { lipStatus = .lowerHeavy }

        let philtrumStatus: PhiltrumStatus
        if (1.6...2.4).contains(philtrumRatio) { philtrumStatus = .ideal }
        else if philtrumRatio < 1.6 { philtrumStatus = .philtrumLong }
        else { philtrumStatus = .chinLong }

        let tol = mouthW * 0.12
        let alignment: AlignmentStatus = alignPx < tol ? .ideal : .off

        let hits = [lipStatus == .ideal, philtrumStatus == .ideal, alignment == .ideal].filter { $0 }.count

        return Result(
            mouthWidthPx: mouthW, upperLipThicknessPx: upper, lowerLipThicknessPx: lower,
            lipRatio: lipRatio,
            philtrumTopPx: philtrumTop, philtrumBotPx: philtrumBot, philtrumRatio: philtrumRatio,
            irisEdgeAlignPx: alignPx, mouthToFaceRatio: mouthToFace,
            lipStatus: lipStatus, philtrumStatus: philtrumStatus, alignmentStatus: alignment,
            hitsOutOf3: hits
        )
    }
}
