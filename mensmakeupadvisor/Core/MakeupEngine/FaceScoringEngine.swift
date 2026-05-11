import Foundation
import UIKit

// 顔判定エンジン (2.1–2.2.8 を統合したトップレベル)
//
// makeup_claude の 2 章「顔判定」の出力を、アプリ既存の `AnalysisResult`/`FaceScore`
// に変換する。
//   - faceShape  ← 2.1 骨格判定
//   - "骨格バランス" ← 2.1 のスコア (best タイプとの近さ)
//   - "三分割比率"   ← 2.2.2 traditional/reiwa の min loss
//   - "五分割比率"   ← 2.2.3 ideal/jp の min loss
//   - "目の比率"     ← 2.2.4 縦横比 + 対称性
//   - "鼻のバランス" ← 2.2.5 4項目ヒット数
//   - "口の比率"     ← 2.2.6 3項目ヒット数
//   - "左右対称性"   ← 2.2.8 overall_sym + jaw_sharpness
enum FaceScoringEngine {
    static func evaluate(image: UIImage) throws -> AnalysisResult {
        let mesh = FaceMesh(subdivisionLevel: 1)
        try mesh.initialize()
        _ = try mesh.detect(image: image)
        return evaluate(faceMesh: mesh)
    }

    static func evaluate(faceMesh: FaceMesh) -> AnalysisResult {
        let symmetry = SymmetryJudge.analyze(faceMesh: faceMesh)
        let sub = symmetry.sub

        // ----- スコア (各 0-100) -----
        // 骨格バランス: best タイプのスコア (0-1) を 50-100 に写像
        let bestType = sub.skeletal.type
        let bestScore = sub.skeletal.scores[bestType] ?? 0
        let skeletalScore = clamp(50 + bestScore * 50)

        // 三分割
        let vertLoss = min(sub.vertical.traditionalLoss, sub.vertical.reiwaLoss)
        let verticalScore = lossToScore(vertLoss, scale: 333.3)

        // 五分割
        let horizLoss = min(sub.horizontal.idealLoss1, sub.horizontal.jpLoss)
        let horizScore = lossToScore(horizLoss, scale: 333.3)

        // 目
        let eyeScore = (lossToScore(sub.eye.idealRatioLoss * 3, scale: 333.3) * 0.5
                        + sub.eye.symmetryScore * 100 * 0.5)

        // 鼻
        let noseScore = Double(sub.nose.hitsOutOf4) / 4.0 * 100.0

        // 口
        let mouthScore = Double(sub.mouth.hitsOutOf3) / 3.0 * 100.0

        // 対称性
        let symScore = (symmetry.overallSym * 0.7 + symmetry.jawLineSharpness * 0.3) * 100.0

        let names = ["骨格バランス", "三分割比率", "五分割比率", "目の比率", "鼻のバランス", "口の比率", "左右対称性"]
        let raw = [skeletalScore, verticalScore, horizScore, eyeScore, noseScore, mouthScore, symScore]
        let scores = zip(names, raw).map { name, value in
            let intScore = Int(value.rounded())
            return FaceScore(name: name, score: clampInt(intScore), advice: FaceScore.pickAdvice(name: name, score: clampInt(intScore)))
        }

        return AnalysisResult(faceShape: bestType.faceShape, scores: scores)
    }

    private static func clamp(_ value: Double) -> Double {
        min(100, max(0, value))
    }

    private static func clampInt(_ value: Int) -> Int {
        min(98, max(40, value))
    }

    // loss は「0 が最良」。Python 版 `_score_loss` を踏襲。
    private static func lossToScore(_ loss: Double, scale: Double = 333.3) -> Double {
        max(0.0, 100.0 - loss * scale)
    }
}
