struct MakeupPreset: Identifiable, Sendable {
    let id: String
    let label: String
    let tag: String
    let intensity: MakeupIntensity

    static let all: [MakeupPreset] = [
        .init(id: "natural",  label: "ナチュラル", tag: "バレない",  intensity: .init(base: 22, highlight: 18, shadow: 14, eye: 12, eyebrow: 28)),
        .init(id: "kireime",  label: "キレイめ",   tag: "オフィス",  intensity: .init(base: 30, highlight: 25, shadow: 22, eye: 20, eyebrow: 38)),
        .init(id: "mode",     label: "モード",     tag: "クール",    intensity: .init(base: 28, highlight: 32, shadow: 35, eye: 32, eyebrow: 45)),
        .init(id: "k-style",  label: "Kスタイル",  tag: "SNS映え",  intensity: .init(base: 35, highlight: 40, shadow: 28, eye: 42, eyebrow: 55)),
    ]
}
