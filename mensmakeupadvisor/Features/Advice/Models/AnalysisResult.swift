import SwiftUI

struct AnalysisResult: Sendable {
    let faceShape: FaceShape
    let scores: [FaceScore]

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
        case 85...: "exceptional"
        case 75...: "excellent"
        case 65...: "good balance"
        case 55...: "standard"
        default: "needs care"
        }
    }

    var rankPercentile: String {
        switch totalScore {
        case 90...: "上位 約3%"
        case 85...: "上位 約8%"
        case 80...: "上位 約15%"
        case 75...: "上位 約22%"
        case 70...: "上位 約31%"
        case 65...: "上位 約42%"
        case 60...: "上位 約55%"
        case 55...: "上位 約67%"
        default: "上位 約80%"
        }
    }

    var strongestScore: FaceScore? { scores.max(by: { $0.score < $1.score }) }
    var weakestScore: FaceScore? { scores.min(by: { $0.score < $1.score }) }
}
