import Foundation

// 化粧の種類。1 種類 = 1 化粧単位 (MakeupUnit)。
// 旧 MakeupLayer の eye を eyeshadow / tearbag / eyeliner に分割している。
nonisolated enum MakeupKind: String, CaseIterable, Sendable, Hashable {
    case base
    case highlight
    case shadow
    case eyeshadow
    case tearbag
    case eyeliner
    case eyebrow

    var labelJP: String {
        switch self {
        case .base:      "ベース"
        case .highlight: "ハイライト"
        case .shadow:    "シェーディング"
        case .eyeshadow: "アイシャドウ"
        case .tearbag:   "涙袋"
        case .eyeliner:  "アイライン"
        case .eyebrow:   "眉"
        }
    }

    // 合成順。base から順に重ねる。combinedColor もこの順で畳み込む。
    var renderOrder: Int {
        switch self {
        case .base:      0
        case .highlight: 1
        case .shadow:    2
        case .eyeshadow: 3
        case .tearbag:   4
        case .eyeliner:  5
        case .eyebrow:   6
        }
    }

    // この化粧の既定色 (MakeupRenderer の従来定数に一致)。alpha は 0。
    var defaultColor: MeshColor {
        switch self {
        case .base:      MeshColor(r: 235, g: 200, b: 170, a: 0)
        case .highlight: MeshColor(r: 255, g: 255, b: 255, a: 0)
        case .shadow:    MeshColor(r: 139, g: 90,  b: 43,  a: 0)
        case .eyeshadow: MeshColor(r: 120, g: 72,  b: 64,  a: 0)
        case .tearbag:   MeshColor(r: 240, g: 220, b: 210, a: 0)
        case .eyeliner:  MeshColor(r: 30,  g: 24,  b: 22,  a: 0)
        case .eyebrow:   MeshColor(r: 85,  g: 60,  b: 45,  a: 0)
        }
    }

    // 指定強度 (0–1) を乗せた既定色。
    func color(intensity: Float) -> MeshColor {
        defaultColor.withIntensity(intensity)
    }

    // target.json のどのカテゴリに属するか。base/eyebrow は専用扱いで nil。
    var meshAreaCategory: MeshAreaCategory? {
        switch self {
        case .base:                           nil
        case .highlight:                      .highlight
        case .shadow:                         .shadow
        case .eyeshadow, .tearbag, .eyeliner: .eye
        case .eyebrow:                        .eyebrow
        }
    }

    // target.json の eye エリア名 → どの化粧単位に属するか。
    static func eyeKind(forArea name: String) -> MakeupKind {
        switch name {
        case "tear_bag": .tearbag
        case "eyeliner": .eyeliner
        default:         .eyeshadow   // eyeshadow_base / eyeshadow_crease / lower_outer
        }
    }
}
