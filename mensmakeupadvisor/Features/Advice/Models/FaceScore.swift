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

    // 骨格（顔の縦横比 = faceAspect = 顔高 / 顔幅）。
    // 縦長 → 上下を圧縮し横へ広げる。横長 → 両サイドを締めて縦を通す。
    private nonisolated static func skeletalAdvice(score: Int, metrics: FaceMetrics) -> String {
        let aspect = metrics.faceAspect
        if aspect >= 1.45 {
            return "顔の縦横比が縦に長め。間延びして面長に見えやすいので、生え際とあご先にシェーディングを置いて縦を圧縮し、頬の高い位置にハイライトとチークを横方向に入れて横幅を足すと、丸みが出てバランスが締まる。"
        }
        if aspect > 0, aspect <= 1.30 {
            return "顔の縦横比が横に広め。丸く幅広に見えやすいので、フェイスライン両サイドとエラにシェーディングを入れて横を引き締め、額の中央〜あごへ縦にハイライトを通すと、縦の距離が強調されて引き締まる。"
        }
        if score >= 75 {
            return "縦横比のバランスが良く、骨格そのものが強み。シェーディングは輪郭をなぞる最小限でいい。"
        }
        return "縦横比はほぼ標準。やや気になる方向（縦長なら上下、横長なら両サイド）に薄くシェーディングを足すと立体感が引き立つ。"
    }

    // 三分割（額 : 中顔面 : 下顔面）。長い区画を陰影で詰める。
    private nonisolated static func verticalAdvice(vertical: VerticalThirdsJudge.Result) -> String {
        switch vertical.category {
        case .traditionalBalanced, .reiwaSmallFace:
            "額・中顔面・下顔面がほぼ理想の1:1:1。縦の三分割は強みなので、ベースは均一に整える程度でいい。"
        case .upperDominant:
            "額（上顔面）が長く、上半分が間延びして見えやすい。前髪を下ろして額の面積を狭め、眉はやや下げ気味かつ太めに描いて、上下の余白を詰めるとバランスが整う。"
        case .middleDominant:
            "中顔面（眉〜鼻下）が長く、のっぺり間延びして見えやすい。眉下〜目元のアイシャドウとノーズシャドウで中央に濃淡を集め、視線を目元へ寄せると間延びが締まる。"
        case .lowerDominant:
            "下顔面（鼻下〜あご）が長め。あご先と下唇の下にシェーディングを入れて縦を圧縮し、リップは少しオーバー気味に取って鼻下の余白を詰めると整う。"
        }
    }

    // 五分割（目の横配置）。寄り目は外へ、離れ目は内へ重心を動かす。
    private nonisolated static func horizontalAdvice(horizontal: HorizontalFifthsJudge.Result) -> String {
        switch horizontal.category {
        case .ideal:
            "目の間隔と目幅の比率が理想的。求心/遠心のバランスが取れていて強み。"
        case .centerConverged:
            "目の間隔が狭い求心顔で、中央に寄って見えやすい。目頭側のアイシャドウは控えめにし、目尻方向へ横長に広げて引くと重心が外へ移り、離れた印象に整う。"
        case .centerDiverged:
            "目の間隔が広い遠心顔で、中央が間延びして見えやすい。目頭にブラウンシャドウとノーズシャドウを効かせ、アイラインも目頭側を濃く入れると、中央に寄って締まって見える。"
        }
    }

    // 目の縦横比（約1:3が理想）。縦長は横へ、横長は縦へ伸ばす。
    private nonisolated static func eyeAdvice(eye: EyeJudge.Result) -> String {
        switch eye.category {
        case .balanced:
            "目の縦横比が理想的（約1:3）。アイラインで印象を微調整する程度でいい。"
        case .bigRound:
            "目が縦に大きく丸い印象で、横の距離感が出にくい。アイラインを目尻へ水平に長く引き出すと横方向に伸び、間延びが締まって落ち着いた目元になる。"
        case .narrow:
            "目の縦横比が横に長く、開きが控えめ。上まぶた中央のアイシャドウと涙袋のハイライトで縦幅を補い、まつ毛を根元から上げると縦に開いて目力が出る。"
        }
    }

    // 鼻幅（対 目間）と鼻の長さ。広い→締める、狭い→高さを足す。
    private nonisolated static func noseAdvice(score: Int, nose: NoseJudge.Result) -> String {
        if nose.wingToGapRatio > 1.12 {
            return "小鼻の幅が目の間隔より広め。横に広がって低く見えやすいので、小鼻の脇に沿ってノーズシャドウで幅を引き締め、鼻筋に細くハイライトを通すと高さが出て鼻筋が通る。"
        }
        if nose.wingToGapRatio > 0, nose.wingToGapRatio < 0.88 {
            return "小鼻の幅が狭め。シェーディングは入れ過ぎず、鼻筋に細くハイライトを入れて高さだけ強調するとバランスが整う。"
        }
        if nose.lengthToWingRatio > 1.9 {
            return "鼻が縦に長め。鼻先と小鼻にかけてシェーディングを軽く入れて長さを詰め、ハイライトは鼻筋の上半分までに留めると間延びが和らぐ。"
        }
        if score >= 75 {
            return "鼻幅と目間の調和が取れている。ノーズシャドウは鼻筋に軽く添える程度で十分。"
        }
        return "鼻筋にノーズシャドウとハイライトを薄く重ねて、立体感を補強したい。"
    }

    // 上下唇の厚み比（下/上が1.2〜2.2で理想）と人中の長さ。
    private nonisolated static func mouthAdvice(mouth: MouthJudge.Result) -> String {
        switch mouth.lipStatus {
        case .ideal:
            if mouth.philtrumStatus == .philtrumLong {
                "上下の唇の厚みは理想的。ただ鼻下（人中）が長めなので、上唇の山をオーバーライン気味に取って人中を短く見せると、間延びが締まる。"
            } else {
                "上下の唇の厚みバランスが整っている。リップは軽く陰影を足す程度でいい。"
            }
        case .upperHeavy:
            "上唇が下唇より縦に厚く、口元が重く見えやすい。下唇の中央にハイライトを入れてふっくら見せ、上唇は締め色を重ねると上下の厚みが近づく。"
        case .lowerHeavy:
            "下唇が縦に厚く、もったり見えやすい。下唇は引き締め色で少し細く見せ、上唇はリップをオーバー気味に取って、上下の厚みを揃える。"
        }
    }

    // 左右対称性。差が大きい側（眉/目）に合わせて整える。
    private nonisolated static func symmetryAdvice(
        score: Int, eye: EyeJudge.Result, eyebrow: EyebrowJudge.Result
    ) -> String {
        if score >= 75 {
            return "左右対称性が高い。整った印象の土台ができている。"
        }
        if eyebrow.symmetryScore < eye.symmetryScore {
            return "左右で眉の差が目立ち、顔全体が傾いて見えやすい。低い側の眉を少し上げ、山の位置と太さを高い側に合わせて描くと、歪み感が和らぐ。"
        }
        return "左右で目元の差が目立つ。小さく見える側のアイラインとマスカラを少し強め、二重幅も合わせると、左右の存在感が均一になる。"
    }
}
