struct TutorialStep: Identifiable, Sendable {
    let id: Int
    let tag: String
    let label: String
    let labelJP: String
    let desc: String
    let layer: MakeupLayer

    static let all: [TutorialStep] = [
        .init(
            id: 0, tag: "I", label: "Highlight", labelJP: "ハイライト",
            desc: "Tゾーン・Cゾーンに光を入れて立体感を演出。鼻筋・頬骨・あごに、自然な輝きをプラス。",
            layer: .highlight
        ),
        .init(
            id: 1, tag: "II", label: "Shadow", labelJP: "シェーディング",
            desc: "小顔効果のための影。輪郭・こめかみに陰影を入れて顔をシャープに。",
            layer: .shadow
        ),
        .init(
            id: 2, tag: "III", label: "Base", labelJP: "ベース",
            desc: "肌のトーンを整える土台。色ムラやくすみを抑えて、均一な肌感を演出。",
            layer: .base
        ),
        .init(
            id: 3, tag: "IV", label: "Eye", labelJP: "アイ",
            desc: "アイシャドウ・アイライナー・涙袋で目元を強調。印象に残る目元に。",
            layer: .eye
        ),
        .init(
            id: 4, tag: "V", label: "Brow", labelJP: "眉",
            desc: "顔の印象を決める眉。形と濃さで、全体の雰囲気を整える。",
            layer: .eyebrow
        ),
    ]
}
