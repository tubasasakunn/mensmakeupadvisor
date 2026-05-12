import CoreGraphics
import Foundation

// 2.2.8 左右対称性・骨格感の総合判定
// makeup_claude/loadmap/2/2.2.8-symmetry/main.py の `analyze` を移植。
// 2.1〜2.2.7 の各判定結果を集約して総合スコアを計算する。
nonisolated enum SymmetryJudge {
    nonisolated struct SubResults: Sendable {
        var skeletal: SkeletalClassifier.Result
        var faceRatio: FaceRatioJudge.Result
        var vertical: VerticalThirdsJudge.Result
        var horizontal: HorizontalFifthsJudge.Result
        var eye: EyeJudge.Result
        var nose: NoseJudge.Result
        var mouth: MouthJudge.Result
        var eyebrow: EyebrowJudge.Result
    }

    nonisolated struct Result: Sendable {
        var eyeSym: Double
        var browSym: Double
        var faceContourSym: Double
        var overallSym: Double

        var jawLineSharpness: Double
        var cheekRatioR: Double
        var cheekRatioL: Double

        var goldenScore: Double  // 0-100
        var goldenLabel: String

        var sub: SubResults
    }

    private nonisolated static func sym(_ a: Double, _ b: Double) -> Double {
        let m = (a + b) / 2
        return m < 1e-6 ? 1.0 : max(0.0, 1.0 - abs(a - b) / m)
    }

    private nonisolated static func jawLineSharpness(faceMesh: FaceMesh) -> Double {
        let mids = [172, 136, 150, 149, 176, 148]
        let g = faceMesh.landmarksPx[FaceLandmarkID.gonionR]
        let c = faceMesh.landmarksPx[FaceLandmarkID.chinBottom]
        let abx = Double(c.x - g.x)
        let aby = Double(c.y - g.y)
        let abLen = hypot(abx, aby)
        if abLen < 1e-3 { return 0 }
        var dists: [Double] = []
        for idx in mids where faceMesh.landmarksPx.indices.contains(idx) {
            let p = faceMesh.landmarksPx[idx]
            let cross = abx * Double(p.y - g.y) - aby * Double(p.x - g.x)
            dists.append(abs(cross) / abLen)
        }
        guard !dists.isEmpty else { return 0 }
        let avg = dists.reduce(0, +) / Double(dists.count) / abLen
        return max(0.0, 1.0 - avg * 4.0)
    }

    nonisolated static func analyze(faceMesh: FaceMesh) -> Result {
        let sub = SubResults(
            skeletal: SkeletalClassifier.classify(faceMesh: faceMesh),
            faceRatio: FaceRatioJudge.analyze(faceMesh: faceMesh),
            vertical: VerticalThirdsJudge.analyze(faceMesh: faceMesh),
            horizontal: HorizontalFifthsJudge.analyze(faceMesh: faceMesh),
            eye: EyeJudge.analyze(faceMesh: faceMesh),
            nose: NoseJudge.analyze(faceMesh: faceMesh),
            mouth: MouthJudge.analyze(faceMesh: faceMesh),
            eyebrow: EyebrowJudge.analyze(faceMesh: faceMesh)
        )

        let eyeSym = sub.eye.symmetryScore
        let browSym = sub.eyebrow.symmetryScore
        let cr = faceMesh.landmarksPx[FaceLandmarkID.cheekboneR]
        let cl = faceMesh.landmarksPx[FaceLandmarkID.cheekboneL]
        let nose = faceMesh.landmarksPx[FaceLandmarkID.noseTip]
        let rHalf = abs(Double(cr.x - nose.x))
        let lHalf = abs(Double(cl.x - nose.x))
        let contourSym = sym(rHalf, lHalf)
        let overallSym = (eyeSym + browSym + contourSym) / 3.0

        let jawSharp = jawLineSharpness(faceMesh: faceMesh)

        let noseR = faceMesh.landmarksPx[FaceLandmarkID.noseWingR]
        let noseL = faceMesh.landmarksPx[FaceLandmarkID.noseWingL]
        let irisRc = FaceMetricsCalculator.mean(faceMesh, ids: FaceLandmarkID.irisR)
        let irisLc = FaceMetricsCalculator.mean(faceMesh, ids: FaceLandmarkID.irisL)
        let rContour = faceMesh.landmarksPx[FaceLandmarkID.gonionR]
        let lContour = faceMesh.landmarksPx[FaceLandmarkID.gonionL]

        let rNoseToCnt = abs(Double(rContour.x - noseR.x))
        let rIrisToCnt = abs(Double(rContour.x - irisRc.x))
        let lNoseToCnt = abs(Double(lContour.x - noseL.x))
        let lIrisToCnt = abs(Double(lContour.x - irisLc.x))

        let cheekR = rNoseToCnt > 1e-3 ? rIrisToCnt / rNoseToCnt : 0
        let cheekL = lNoseToCnt > 1e-3 ? lIrisToCnt / lNoseToCnt : 0

        // ----- 総合黄金比スコア -----
        let weights: [String: Double] = [
            "face_ratio_loss": 15, "vertical_loss": 15, "horizontal_loss": 10,
            "eye_ratio_loss": 10, "eye_sym": 5,
            "nose_wing_loss": 5, "nose_len_loss": 5,
            "mouth_lip": 5, "mouth_phil": 5,
            "brow_peak_loss": 5, "brow_sym": 5,
            "contour_sym": 5, "jaw_sharpness": 10,
        ]
        func scoreLoss(_ loss: Double) -> Double { max(0.0, 100.0 - loss * 333.3) }

        var score = 0.0
        let faceRatioLoss = sub.faceRatio.losses[sub.faceRatio.closestRatio] ?? 0
        score += scoreLoss(faceRatioLoss) * (weights["face_ratio_loss"] ?? 0)
        score += scoreLoss(min(sub.vertical.traditionalLoss, sub.vertical.reiwaLoss)) * (weights["vertical_loss"] ?? 0)
        score += scoreLoss(min(sub.horizontal.idealLoss1, sub.horizontal.jpLoss)) * (weights["horizontal_loss"] ?? 0)
        score += scoreLoss(sub.eye.idealRatioLoss * 3) * (weights["eye_ratio_loss"] ?? 0)
        score += sub.eye.symmetryScore * 100 * (weights["eye_sym"] ?? 0)
        score += scoreLoss(sub.nose.wingLoss) * (weights["nose_wing_loss"] ?? 0)
        score += scoreLoss(sub.nose.lengthLoss) * (weights["nose_len_loss"] ?? 0)
        score += scoreLoss(abs(sub.mouth.lipRatio - 1.75) / 1.75) * (weights["mouth_lip"] ?? 0)
        score += scoreLoss(abs(sub.mouth.philtrumRatio - 2.0) / 2.0) * (weights["mouth_phil"] ?? 0)
        score += scoreLoss(abs(sub.eyebrow.right.peakRatio - 2.0) / 2.0) * (weights["brow_peak_loss"] ?? 0)
        score += sub.eyebrow.symmetryScore * 100 * (weights["brow_sym"] ?? 0)
        score += contourSym * 100 * (weights["contour_sym"] ?? 0)
        score += jawSharp * 100 * (weights["jaw_sharpness"] ?? 0)

        let total = weights.values.reduce(0, +)
        let golden = total > 0 ? score / total : 0

        let label: String
        switch golden {
        case 85...: label = "S (Excellent)"
        case 75...: label = "A (Good)"
        case 65...: label = "B (Average)"
        default: label = "C (Needs Work)"
        }

        return Result(
            eyeSym: eyeSym, browSym: browSym, faceContourSym: contourSym, overallSym: overallSym,
            jawLineSharpness: jawSharp, cheekRatioR: cheekR, cheekRatioL: cheekL,
            goldenScore: golden, goldenLabel: label, sub: sub
        )
    }
}
