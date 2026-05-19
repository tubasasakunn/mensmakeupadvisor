import SwiftUI

nonisolated struct FaceScore: Identifiable, Sendable {
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
    private nonisolated static let adviceDict: [String: (high: String, mid: String, low: String)] = [
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

    nonisolated static func pickAdvice(name: String, score: Int) -> String {
        guard let entry = adviceDict[name] else { return "" }
        switch score {
        case 75...: return entry.high
        case 55...: return entry.mid
        default:    return entry.low
        }
    }
}

// MARK: - Direction-aware Advice

// スコアの high/mid/low だけでなく、比率の「向き」（縦長/横長・上唇/下唇・
// 寄り目/離れ目など）で文言を出し分ける。判定器の category/status を使う。
extension FaceScore {
    nonisolated static func pickAdvice(
        name: String, score: Int,
        sub: SymmetryJudge.SubResults, metrics: FaceMetrics
    ) -> String {
        switch name {
        case "骨格バランス": skeletalAdvice(score: score, metrics: metrics)
        case "三分割比率":   verticalAdvice(vertical: sub.vertical)
        case "五分割比率":   horizontalAdvice(horizontal: sub.horizontal)
        case "目の比率":     eyeAdvice(eye: sub.eye)
        case "鼻のバランス": noseAdvice(score: score, nose: sub.nose)
        case "口の比率":     mouthAdvice(mouth: sub.mouth)
        case "左右対称性":   symmetryAdvice(score: score, eye: sub.eye, eyebrow: sub.eyebrow)
        default:             pickAdvice(name: name, score: score)
        }
    }

    private nonisolated static func skeletalAdvice(score: Int, metrics: FaceMetrics) -> String {
        if score >= 75 {
            return "縦横比のバランスが良く、骨格そのものが強み。シェーディングは最小限でいい。"
        }
        if metrics.faceAspect >= 1.45 {
            return "顔が縦長傾向。額の生え際とあご先にシェーディングを置いて縦を圧縮、頬のハイライトで横幅を補うと整う。"
        }
        if metrics.faceAspect > 0, metrics.faceAspect <= 1.30 {
            return "顔が横長傾向。フェイスライン両サイドのシェーディングで横幅を引き締めると縦横比が締まる。"
        }
        return "縦横比にやや偏りあり。気になる方向にシェーディングを足して立体感をコントロール。"
    }

    private nonisolated static func verticalAdvice(vertical: VerticalThirdsJudge.Result) -> String {
        switch vertical.category {
        case .traditionalBalanced, .reiwaSmallFace:
            "額・中顔面・下顔面が、ほぼ理想の1:1:1。三分割は触らなくていい。"
        case .upperDominant:
            "額（上顔面）が長め。前髪を下ろす、または眉をやや上げて上下のバランスを詰めたい。"
        case .middleDominant:
            "中顔面（眉〜鼻下）が長め。眉下〜目元に濃淡をつけて間延びを抑えると締まる。"
        case .lowerDominant:
            "下顔面（鼻下〜あご）が長め。あご先のシェーディングで縦を圧縮するとバランスが整う。"
        }
    }

    private nonisolated static func horizontalAdvice(horizontal: HorizontalFifthsJudge.Result) -> String {
        switch horizontal.category {
        case .ideal:
            "目間・目幅の比率が理想的。求心/遠心のバランスが取れている。"
        case .centerConverged:
            "目の間隔がやや狭い（求心顔）。目頭側は控えめに、アイシャドウを目尻方向へ広げて外へ重心を移す。"
        case .centerDiverged:
            "目の間隔がやや広い（遠心顔）。目頭にシェーディング、アイラインは目頭側を濃くして内側に寄せる。"
        }
    }

    private nonisolated static func eyeAdvice(eye: EyeJudge.Result) -> String {
        switch eye.category {
        case .balanced:
            "目の縦横比が理想的（約1:3）。アイラインで印象を微調整する程度でいい。"
        case .bigRound:
            "目が縦に大きく丸い印象。アイラインを目尻へ長めに引くと横方向に伸びて洗練される。"
        case .narrow:
            "目が横長で細め。涙袋のハイライトと上まぶたのアイシャドウで縦幅を補うと目力が出る。"
        }
    }

    private nonisolated static func noseAdvice(score: Int, nose: NoseJudge.Result) -> String {
        if nose.wingToGapRatio > 1.12 {
            return "小鼻の幅が広め。小鼻の脇にノーズシャドウを入れて幅を引き締めると鼻筋が通る。"
        }
        if nose.wingToGapRatio > 0, nose.wingToGapRatio < 0.88 {
            return "小鼻の幅が狭め。鼻筋に細くハイライトを入れて高さを強調するとバランスが整う。"
        }
        if score >= 75 {
            return "鼻幅と目間の調和が取れている。ノーズシャドウは軽く添える程度で十分。"
        }
        return "鼻筋にノーズシャドウとハイライトを薄く重ねて、立体感を補強したい。"
    }

    private nonisolated static func mouthAdvice(mouth: MouthJudge.Result) -> String {
        switch mouth.lipStatus {
        case .ideal:
            if mouth.philtrumStatus == .philtrumLong {
                "上下の唇の厚みは理想的。鼻下（人中）が長めなので、上唇をややオーバー気味に取ると間延びが締まる。"
            } else {
                "上下の唇の厚みバランスが整っている。リップは軽く陰影を足す程度でいい。"
            }
        case .upperHeavy:
            "上唇が下唇より縦に厚め。下唇の中央にハイライトを入れてふっくら見せ、上下の厚みを近づける。"
        case .lowerHeavy:
            "下唇が縦に厚め。下唇は引き締め色でやや細く見せ、上唇はリップをオーバー気味に取って上下を揃える。"
        }
    }

    private nonisolated static func symmetryAdvice(
        score: Int, eye: EyeJudge.Result, eyebrow: EyebrowJudge.Result
    ) -> String {
        if score >= 75 {
            return "左右対称性が高い。整った印象の土台ができている。"
        }
        if eyebrow.symmetryScore < eye.symmetryScore {
            return "眉の左右差が目立つ。低い側の眉を少し上げ、山の位置と太さを高い側に合わせると揃う。"
        }
        return "目元の左右差が目立つ。小さく見える側のアイメイクを少し強めて、左右の存在感を均一にする。"
    }
}
