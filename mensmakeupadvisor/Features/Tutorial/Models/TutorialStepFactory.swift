import Foundation

// 顔型ごとに「どのゾーンを順に見せるか」のリストを組み立てる。
// テキスト (explanation) は TutorialStepExplanations が責任を持つ。
enum TutorialStepFactory {
    static func baseStep(for f: FaceShape) -> TutorialStep {
        TutorialStep(
            id: "base", tag: "I", layer: .base, areaName: nil,
            titleJP: "ベース",
            explanation: TutorialStepExplanations.base(for: f),
            oneLiner: "肌の色ムラを整える、すべての土台。"
        )
    }

    static func highlightSteps(for f: FaceShape) -> [TutorialStep] {
        highlightEntries(for: f).map { entry in
            TutorialStep(
                id: "highlight.\(entry.area)", tag: "",
                layer: .highlight, areaName: entry.area,
                titleJP: "ハイライト · \(entry.title)",
                explanation: TutorialStepExplanations.highlight(for: f, area: entry.area),
                oneLiner: entry.oneLiner
            )
        }
    }

    static func shadowSteps(for f: FaceShape) -> [TutorialStep] {
        shadowEntries(for: f).map { entry in
            TutorialStep(
                id: "shadow.\(entry.area)", tag: "",
                layer: .shadow, areaName: entry.area,
                titleJP: "シェード · \(entry.title)",
                explanation: TutorialStepExplanations.shadow(for: f, area: entry.area),
                oneLiner: entry.oneLiner
            )
        }
    }

    static func eyeSteps(for f: FaceShape) -> [TutorialStep] {
        eyeEntries().map { entry in
            TutorialStep(
                id: "eye.\(entry.area)", tag: "",
                layer: .eye, areaName: entry.area,
                titleJP: "アイ · \(entry.title)",
                explanation: TutorialStepExplanations.eye(for: f, area: entry.area),
                oneLiner: entry.oneLiner
            )
        }
    }

    static func browStep(for f: FaceShape) -> TutorialStep {
        let (type, title) = recommendedBrow(for: f)
        return TutorialStep(
            id: "brow.\(type)", tag: "",
            layer: .eyebrow, areaName: type,
            titleJP: "眉 · \(title)",
            explanation: TutorialStepExplanations.brow(for: f, type: type),
            oneLiner: "顔の印象を決定づける最後のひと筆。"
        )
    }
}

// MARK: - 顔型ごとのゾーン定義

private struct ZoneEntry {
    let area: String
    let title: String
    let oneLiner: String
}

private extension TutorialStepFactory {
    static func highlightEntries(for f: FaceShape) -> [ZoneEntry] {
        switch f {
        case .tamago, .gyaku, .base:
            return [
                ZoneEntry(area: "base_t-zone",    title: "Tゾーン (額・鼻筋)", oneLiner: "光の縦線を入れて中心を高く。"),
                ZoneEntry(area: "base_c-zone",    title: "Cゾーン (頬骨)",     oneLiner: "頬骨に光を置いて立体に。"),
                ZoneEntry(area: "base_under-eye", title: "目の下",             oneLiner: "影を散らして明るく若々しく。"),
                ZoneEntry(area: "base_megasira",  title: "目頭",               oneLiner: "顔の中心に光を集めて求心的に。"),
                ZoneEntry(area: "base_zintyuu",   title: "鼻の下 (人中)",       oneLiner: "鼻筋を縦に伸ばして大人っぽく。"),
            ]
        case .marugao:
            return [
                ZoneEntry(area: "marugao_t-zone", title: "Tゾーン (丸顔)", oneLiner: "中央に縦長の光で輪郭を引き締める。"),
                ZoneEntry(area: "marugao_c-zone", title: "Cゾーン (丸顔)", oneLiner: "頬上部のみに光を置いて頬骨を強調。"),
                ZoneEntry(area: "marugao_ago",    title: "あご先",         oneLiner: "縦の延長線で顔長感をプラス。"),
            ]
        case .omonaga:
            return [
                ZoneEntry(area: "omonaga_t-zone", title: "Tゾーン (面長)", oneLiner: "額の中央寄りだけ光らせて横を広く見せる。"),
                ZoneEntry(area: "omonaga_c-zone", title: "Cゾーン (面長)", oneLiner: "頬の横方向に広く光で奥行きを足す。"),
            ]
        }
    }

    static func shadowEntries(for f: FaceShape) -> [ZoneEntry] {
        switch f {
        case .tamago:
            return [ZoneEntry(area: "omonaga-lower", title: "あごのシェード", oneLiner: "顎下に影でフェイスラインを引き締める。")]
        case .marugao:
            return [ZoneEntry(area: "marugao-side",  title: "頬の輪郭",       oneLiner: "横の影で縦長シルエットに。")]
        case .omonaga:
            return [
                ZoneEntry(area: "omonaga-upper", title: "額のシェード",   oneLiner: "額の上端に影で縦の長さを抑える。"),
                ZoneEntry(area: "omonaga-lower", title: "あごのシェード", oneLiner: "あご下にも影で重心を中央に。"),
            ]
        case .gyaku:
            return [ZoneEntry(area: "marugao-side",  title: "頬の輪郭",       oneLiner: "頬の横を引いて尖りを和らげる。")]
        case .base:
            return [
                ZoneEntry(area: "marugao-side",  title: "エラの輪郭",     oneLiner: "エラの影で柔らかい印象に。"),
                ZoneEntry(area: "omonaga-lower", title: "あごのシェード", oneLiner: "下方向に影で重心を下げ過ぎない。"),
            ]
        }
    }

    static func eyeEntries() -> [ZoneEntry] {
        [
            ZoneEntry(area: "eyeshadow_base",   title: "まぶた全体",   oneLiner: "陰影の下地で目のフレームを作る。"),
            ZoneEntry(area: "eyeshadow_crease", title: "二重ライン",   oneLiner: "二重幅に影で奥行きを足す。"),
            ZoneEntry(area: "tear_bag",         title: "涙袋",         oneLiner: "目の下の膨らみで若々しい印象に。"),
            ZoneEntry(area: "lower_outer",      title: "下まぶた外側", oneLiner: "目尻の影で横長感を強調。"),
            ZoneEntry(area: "eyeliner",         title: "アイライン",   oneLiner: "縁取って瞳をくっきり見せる。"),
        ]
    }

    static func recommendedBrow(for f: FaceShape) -> (type: String, title: String) {
        switch f {
        case .tamago:  return ("natural",  "ナチュラル")
        case .marugao: return ("straight", "ストレート")
        case .omonaga: return ("straight", "ストレート")
        case .gyaku:   return ("arch",     "アーチ")
        case .base:    return ("arch",     "アーチ")
        }
    }
}
