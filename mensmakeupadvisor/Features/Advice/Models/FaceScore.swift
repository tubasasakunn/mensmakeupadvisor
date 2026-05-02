import SwiftUI

struct FaceScore: Identifiable, Sendable {
    var id: String { name }
    let name: String
    let score: Int
    let advice: String

    var grade: String {
        switch score {
        case 85...: "S"
        case 75...: "A"
        case 65...: "B"
        case 55...: "C"
        default: "D"
        }
    }

    var gradeColor: Color {
        switch score {
        case 65...: Color.ivory
        case 55...: Color.sulphur
        default: Color.brandPrimary
        }
    }
}

// MARK: - Advice Dictionaries

extension FaceScore {
    private static let adviceDict: [String: (high: String, mid: String, low: String)] = [
        "骨格バランス": (
            high: "理想的な縦横比。バランスの取れた骨格は、すべてを許容する。",
            mid:  "やや縦長/横長傾向。シェーディングで縦横比を整えたい。",
            low:  "縦横比に偏りあり。シャドウで顔を立体的にコントロール。"
        ),
        "三分割比率": (
            high: "上・中・下顔面の比率が、ほぼ理想的（1:1:1）。",
            mid:  "微妙にバランスが偏っている。眉位置・前髪で調整可能。",
            low:  "顔の三分割に偏り。眉やヘアラインで印象を整えよう。"
        ),
        "五分割比率": (
            high: "目間・目幅の比率が理想的。求心顔/遠心顔のバランス◎",
            mid:  "やや寄り目/離れ目傾向。アイメイクで目の位置感を調整。",
            low:  "目の配置に偏り。目頭・目尻のシャドウで補正可能。"
        ),
        "目の比率": (
            high: "目の縦横比が理想的（約1:3）。印象に残る目元。",
            mid:  "目の比率は標準。アイラインで縦/横の印象を強化できる。",
            low:  "目元のインパクトが控えめ。涙袋とアイラインで強調を。"
        ),
        "鼻のバランス": (
            high: "鼻幅と目間の調和◎ 立体感のあるバランス。",
            mid:  "鼻のバランスは標準。シェーディングで鼻筋を強調。",
            low:  "鼻幅が広い/狭い傾向。ノーズシャドウで立体感アップ。"
        ),
        "口の比率": (
            high: "上下唇のバランスが整っている。",
            mid:  "リップバランスは標準的。リップで陰影をプラス。",
            low:  "唇の厚みバランスに偏りあり。リップで補正可能。"
        ),
        "左右対称性": (
            high: "左右対称性が高い。整った印象を生む基盤。",
            mid:  "微妙な左右差あり。眉とアイメイクで左右を揃えたい。",
            low:  "左右差が目立つ。眉の高さ・形を左右で調整しよう。"
        ),
    ]

    static func pickAdvice(name: String, score: Int) -> String {
        guard let entry = adviceDict[name] else { return "" }
        switch score {
        case 75...: return entry.high
        case 55...: return entry.mid
        default:    return entry.low
        }
    }
}
