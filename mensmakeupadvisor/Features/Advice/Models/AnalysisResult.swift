import SwiftUI

nonisolated struct AnalysisResult: Sendable {
    let faceShape: FaceShape
    let scores: [FaceScore]
    // DiagnosisView でメッシュ・比率線を画像に重ねるための実検出データ。
    // モック/フォールバックでは nil。
    var landmarksNormalized: [CGPoint]? = nil  // 478点、x/y は 0-1 正規化
    var imageWidthPx: Int? = nil
    var imageHeightPx: Int? = nil
    var metrics: FaceMetrics? = nil
    // engine.prepare で顔周辺に切り出した結果。AnalyzingView で
    // appState.capturedImage を差し替えるのに使う。
    var croppedImage: UIImage? = nil

    init(faceShape: FaceShape, scores: [FaceScore],
         landmarksNormalized: [CGPoint]? = nil,
         imageWidthPx: Int? = nil,
         imageHeightPx: Int? = nil,
         metrics: FaceMetrics? = nil,
         croppedImage: UIImage? = nil) {
        self.faceShape = faceShape
        self.scores = scores
        self.landmarksNormalized = landmarksNormalized
        self.imageWidthPx = imageWidthPx
        self.imageHeightPx = imageHeightPx
        self.metrics = metrics
        self.croppedImage = croppedImage
    }

    var totalScore: Int {
        guard !scores.isEmpty else { return 0 }
        return scores.map(\.score).reduce(0, +) / scores.count
    }

    var grade: String {
        switch totalScore {
        case 85...: "S"
        case 75...: "A"
        case 65...: "B"
        case 55...: "C"
        default: "D"
        }
    }

    var gradeColor: Color {
        switch totalScore {
        case 75...: .ivory
        case 65...: .sulphur
        default: .brandPrimary
        }
    }

    var gradeDescription: String {
        switch totalScore {
        case 85...: "理想的なバランス"
        case 75...: "とても整っている"
        case 65...: "バランス良好"
        case 55...: "標準的"
        default: "伸びしろあり"
        }
    }

    var rankPercentile: String {
        // 否定的・競争的表現を避け、ポジティブリフレーミングする
        switch totalScore {
        case 90...: "整いやすいタイプ"
        case 85...: "バランスが良い"
        case 80...: "強みが多い"
        case 75...: "平均より高め"
        case 70...: "平均より少し高め"
        case 65...: "平均的"
        case 60...: "改善で印象が変わる"
        case 55...: "伸びしろが大きい"
        default: "伸びしろが大きい"
        }
    }

    var strongestScore: FaceScore? { scores.max(by: { $0.score < $1.score }) }
    var weakestScore: FaceScore? { scores.min(by: { $0.score < $1.score }) }
}
