import CoreGraphics
import Foundation

// 2.2.2 顔の垂直三分割判定
// makeup_claude/loadmap/2/2.2.2-vertical/main.py の `analyze` を移植。
nonisolated enum VerticalThirdsJudge {
    nonisolated static let foreheadExtend = 0.13

    nonisolated enum Category: Sendable {
        case traditionalBalanced
        case reiwaSmallFace
        case upperDominant
        case middleDominant
        case lowerDominant
    }

    nonisolated struct Result: Sendable {
        var hairlineY: Double
        var browY: Double
        var subnasalY: Double
        var chinY: Double

        var upperPx: Double
        var middlePx: Double
        var lowerPx: Double

        var upperNorm: Double
        var middleNorm: Double
        var lowerNorm: Double

        var traditionalLoss: Double
        var reiwaLoss: Double
        var closestTraditional: Bool
        var category: Category
    }

    nonisolated static func analyze(faceMesh: FaceMesh) -> Result {
        let topY = Double(faceMesh.landmarksPx[FaceLandmarkID.foreheadTop].y)
        let chinY = Double(faceMesh.landmarksPx[FaceLandmarkID.chinBottom].y)
        let rawH = chinY - topY
        let hairlineY = topY - rawH * foreheadExtend
        let browY = (Double(faceMesh.landmarksPx[FaceLandmarkID.browHeadR].y)
                     + Double(faceMesh.landmarksPx[FaceLandmarkID.browHeadL].y)) / 2
        let subnasalY = Double(faceMesh.landmarksPx[FaceLandmarkID.subnasal].y)

        let upperPx = browY - hairlineY
        let middlePx = subnasalY - browY
        let lowerPx = chinY - subnasalY

        var upperNorm = 0.0
        var lowerNorm = 0.0
        if middlePx > 1e-3 {
            upperNorm = upperPx / middlePx
            lowerNorm = lowerPx / middlePx
        }
        let vec = [upperNorm, 1.0, lowerNorm]
        let trad = [1.0, 1.0, 1.0]
        let reiwa = [1.0, 1.0, 0.8]
        func rmse(_ a: [Double], _ b: [Double]) -> Double {
            let s = zip(a, b).map { ($0 - $1) * ($0 - $1) }.reduce(0, +)
            return sqrt(s / Double(a.count))
        }
        let tLoss = rmse(vec, trad)
        let rLoss = rmse(vec, reiwa)
        let closestTraditional = tLoss < rLoss
        let maxVal = vec.max() ?? 0
        let minVal = vec.min() ?? 1
        let maxIdx = vec.firstIndex(of: maxVal) ?? 0
        let spread = (maxVal - minVal) / max(minVal, 1e-3)

        let category: Category
        if spread < 0.15 {
            category = closestTraditional ? .traditionalBalanced : .reiwaSmallFace
        } else {
            switch maxIdx {
            case 0: category = .upperDominant
            case 1: category = .middleDominant
            default: category = .lowerDominant
            }
        }

        return Result(
            hairlineY: hairlineY, browY: browY, subnasalY: subnasalY, chinY: chinY,
            upperPx: upperPx, middlePx: middlePx, lowerPx: lowerPx,
            upperNorm: upperNorm, middleNorm: 1.0, lowerNorm: lowerNorm,
            traditionalLoss: tLoss, reiwaLoss: rLoss,
            closestTraditional: closestTraditional, category: category
        )
    }
}
