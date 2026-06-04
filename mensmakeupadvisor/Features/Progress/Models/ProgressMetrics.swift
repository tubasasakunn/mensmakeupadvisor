import Foundation
import SwiftUI

// 保存ルック群から「スコアの推移」を導出する純粋な値型。
// SwiftData の [SavedLook] を View 側で @Query し、ここで分析値に畳み込む。
// 状態を持たない読み取り専用の派生計算なので @Observable ViewModel ではなく
// Sendable struct にしている (振る舞いではなく集計のため)。
struct ProgressMetrics: Sendable, Equatable {
    struct Point: Identifiable, Sendable, Equatable {
        let id: String      // SavedLook.id
        let date: Date
        let score: Int
    }

    let points: [Point]     // createdAt 昇順
    let latest: Int
    let best: Int
    let average: Int
    let delta: Int          // 最新 - 最初
    let bestDate: Date?

    var count: Int { points.count }
    var isEmpty: Bool { points.isEmpty }
    var hasTrend: Bool { points.count >= 2 }

    static let empty = ProgressMetrics(
        points: [], latest: 0, best: 0, average: 0, delta: 0, bestDate: nil
    )

    static func make(from looks: [SavedLook]) -> ProgressMetrics {
        // 採点のないルック (totalScore <= 0) は推移の対象外。
        let scored = looks
            .filter { $0.totalScore > 0 }
            .sorted { $0.createdAt < $1.createdAt }
        guard !scored.isEmpty else { return .empty }

        let points = scored.map { Point(id: $0.id, date: $0.createdAt, score: $0.totalScore) }
        let scores = points.map(\.score)
        let latest = scores.last ?? 0
        let first = scores.first ?? 0
        let best = scores.max() ?? 0
        let average = Int((Double(scores.reduce(0, +)) / Double(scores.count)).rounded())
        let bestDate = points.max { $0.score < $1.score }?.date

        return ProgressMetrics(
            points: points,
            latest: latest,
            best: best,
            average: average,
            delta: latest - first,
            bestDate: bestDate
        )
    }

    // 推移の方向に応じた一言。delta の符号で出し分ける。
    var deltaCaption: String {
        guard hasTrend else { return "もう一度保存すると推移が見えます" }
        switch delta {
        case 1...:    return "最初の記録から +\(delta)pt"
        case ..<0:    return "最初の記録から \(delta)pt"
        default:      return "最初の記録から横ばい"
        }
    }
}

// スコア → グレード / グレード色。AnalysisResult と同じ閾値・配色に揃える
// (S/A は ivory、B は sulphur、C/D は bordeaux)。
enum ScoreGrade {
    static func letter(for score: Int) -> String {
        switch score {
        case 85...: "S"
        case 75...: "A"
        case 65...: "B"
        case 55...: "C"
        default:    "D"
        }
    }

    static func color(for score: Int) -> Color {
        switch score {
        case 75...: .ivory
        case 65...: .sulphur
        default:    .brandPrimary
        }
    }
}
