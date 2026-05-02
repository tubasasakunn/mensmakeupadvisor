enum MakeupLayer: String, CaseIterable, Sendable {
    case highlight, shadow, base, eye, eyebrow

    var label: String {
        switch self {
        case .highlight: "Highlight"
        case .shadow:    "Shadow"
        case .base:      "Base"
        case .eye:       "Eye"
        case .eyebrow:   "Brow"
        }
    }

    var labelJP: String {
        switch self {
        case .highlight: "ハイライト"
        case .shadow:    "シェーディング"
        case .base:      "ベース"
        case .eye:       "アイ"
        case .eyebrow:   "眉"
        }
    }

    // Roman numeral tags I–V corresponding to CaseIterable order
    var tag: String {
        switch self {
        case .highlight: "I"
        case .shadow:    "II"
        case .base:      "III"
        case .eye:       "IV"
        case .eyebrow:   "V"
        }
    }
}
