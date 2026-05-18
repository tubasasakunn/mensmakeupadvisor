// エディターズプリセット。各化粧単位に強度 (0–1) を適用する。
// composition の各 unit が持つメッシュはそのままに、強度だけ書き換える。
struct MakeupPreset: Identifiable, Sendable {
    let id: String
    let label: String
    let tag: String
    let intensities: [MakeupKind: Float]

    func apply(to composition: inout MakeupComposition) {
        for (kind, value) in intensities {
            composition.setIntensity(value, for: kind)
        }
    }

    static let all: [MakeupPreset] = [
        .init(id: "natural", label: "ナチュラル", tag: "バレない",
              intensities: [.base: 0.22, .highlight: 0.18, .shadow: 0.14,
                            .eyeshadow: 0.12, .tearbag: 0.12, .eyeliner: 0.12]),
        .init(id: "kireime", label: "キレイめ", tag: "オフィス",
              intensities: [.base: 0.30, .highlight: 0.25, .shadow: 0.22,
                            .eyeshadow: 0.20, .tearbag: 0.18, .eyeliner: 0.20]),
        .init(id: "mode", label: "モード", tag: "クール",
              intensities: [.base: 0.28, .highlight: 0.32, .shadow: 0.35,
                            .eyeshadow: 0.32, .tearbag: 0.22, .eyeliner: 0.35]),
        .init(id: "k-style", label: "Kスタイル", tag: "SNS映え",
              intensities: [.base: 0.35, .highlight: 0.40, .shadow: 0.28,
                            .eyeshadow: 0.42, .tearbag: 0.35, .eyeliner: 0.42]),
    ]
}
