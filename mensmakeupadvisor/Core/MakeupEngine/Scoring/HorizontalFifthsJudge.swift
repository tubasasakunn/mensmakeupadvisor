import Foundation

// 2.2.3 顔の水平五分割判定
// makeup_claude/loadmap/2/2.2.3-horizontal/main.py の `analyze` を移植。
enum HorizontalFifthsJudge {
    static let jpIdeal: [Double] = [1.0, 1.15, 1.0]

    enum Category: Sendable {
        case ideal, centerConverged, centerDiverged
    }

    struct Result: Sendable {
        var segPx: [Double]          // [右余白, 右目幅, 目間, 左目幅, 左余白]
        var segNorm: [Double]
        var eyeGapRatio: Double
        var leftRightBalance: Double
        var idealLoss1: Double       // 1:1:1:1:1 との差
        var jpLoss: Double           // 1:1.15:1 との差
        var closestIdeal11111: Bool
        var category: Category
    }

    static func analyze(faceMesh: FaceMesh) -> Result {
        func x(_ idx: Int) -> Double { Double(faceMesh.landmarksPx[idx].x) }
        let xs = [x(FaceLandmarkID.templeR), x(FaceLandmarkID.templeL)].sorted()
        let xLeftEdge = xs[0]
        let xRightEdge = xs[1]
        let rOut = min(x(FaceLandmarkID.eyeOuterR), x(FaceLandmarkID.eyeInnerR))
        let rIn  = max(x(FaceLandmarkID.eyeOuterR), x(FaceLandmarkID.eyeInnerR))
        let lIn  = min(x(FaceLandmarkID.eyeInnerL), x(FaceLandmarkID.eyeOuterL))
        let lOut = max(x(FaceLandmarkID.eyeInnerL), x(FaceLandmarkID.eyeOuterL))

        let seg1 = rOut - xLeftEdge
        let seg2 = rIn - rOut
        let seg3 = lIn - rIn
        let seg4 = lOut - lIn
        let seg5 = xRightEdge - lOut
        let segPx = [seg1, seg2, seg3, seg4, seg5]

        var segNorm: [Double] = []
        var gapRatio = 0.0
        let eyeMean = (seg2 + seg4) / 2
        if eyeMean > 1e-3 {
            segNorm = segPx.map { $0 / eyeMean }
            gapRatio = seg3 / eyeMean
        } else {
            segNorm = [0, 0, 0, 0, 0]
        }

        func rmse(_ a: [Double], _ b: [Double]) -> Double {
            let s = zip(a, b).map { ($0 - $1) * ($0 - $1) }.reduce(0, +)
            return sqrt(s / Double(a.count))
        }
        let idealLoss1 = rmse(segNorm, [1, 1, 1, 1, 1])
        let jpV = [segNorm[1], segNorm[2], segNorm[3]]
        let jpLoss = rmse(jpV, jpIdeal)

        var balance = 0.0
        if seg1 + seg5 > 1e-3 {
            balance = (seg1 - seg5) / ((seg1 + seg5) / 2)
        }

        let category: Category
        if gapRatio < 1.30 {
            category = .centerConverged
        } else if gapRatio > 1.55 {
            category = .centerDiverged
        } else {
            category = .ideal
        }

        return Result(
            segPx: segPx, segNorm: segNorm,
            eyeGapRatio: gapRatio, leftRightBalance: balance,
            idealLoss1: idealLoss1, jpLoss: jpLoss,
            closestIdeal11111: idealLoss1 < jpLoss, category: category
        )
    }
}
