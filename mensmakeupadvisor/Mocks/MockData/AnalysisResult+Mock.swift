extension AnalysisResult {
    static let mock = AnalysisResult(
        faceShape: .tamago,
        scores: [
            FaceScore(name: "骨格バランス", score: 82, advice: FaceScore.pickAdvice(name: "骨格バランス", score: 82)),
            FaceScore(name: "三分割比率",   score: 74, advice: FaceScore.pickAdvice(name: "三分割比率",   score: 74)),
            FaceScore(name: "五分割比率",   score: 68, advice: FaceScore.pickAdvice(name: "五分割比率",   score: 68)),
            FaceScore(name: "目の比率",     score: 77, advice: FaceScore.pickAdvice(name: "目の比率",     score: 77)),
            FaceScore(name: "鼻のバランス", score: 71, advice: FaceScore.pickAdvice(name: "鼻のバランス", score: 71)),
            FaceScore(name: "口の比率",     score: 65, advice: FaceScore.pickAdvice(name: "口の比率",     score: 65)),
            FaceScore(name: "左右対称性",   score: 79, advice: FaceScore.pickAdvice(name: "左右対称性",   score: 79)),
        ]
    )
}
