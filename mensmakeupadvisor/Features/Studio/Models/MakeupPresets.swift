import Foundation

// Studio で「どこに highlight/shadow を当てるか」をユーザーが切り替えるための
// プリセット。target.json の area 名 prefix と一致する。顔判定結果に応じて
// デフォルトが決まるが、Studio FINE TUNE の選択ボタンで上書きできる。

nonisolated enum HighlightPreset: String, CaseIterable, Sendable, Identifiable {
    case base       // base_t-zone / base_c-zone / base_under-eye / base_megasira / base_zintyuu
    case marugao    // marugao_t-zone / marugao_c-zone / marugao_ago (顎)
    case omonaga    // omonaga_t-zone / omonaga_c-zone
    case off

    nonisolated var id: String { rawValue }
    nonisolated var label: String {
        switch self {
        case .base: "STANDARD"
        case .marugao: "ROUND"
        case .omonaga: "OBLONG"
        case .off: "OFF"
        }
    }
    nonisolated var detail: String {
        switch self {
        case .base: "Tゾーン・Cゾーン・目下"
        case .marugao: "丸顔向け・縦に明るく"
        case .omonaga: "面長向け・横の張りを"
        case .off: "適用しない"
        }
    }
    nonisolated var targetPrefix: String? {
        switch self {
        case .base: "base"
        case .marugao: "marugao"
        case .omonaga: "omonaga"
        case .off: nil
        }
    }
}

nonisolated enum ShadowPreset: String, CaseIterable, Sendable, Identifiable {
    case omonaga   // omonaga-upper / omonaga-lower (額・顎)
    case marugao   // marugao-side (頬の輪郭)
    case both      // omonaga + marugao
    case off

    nonisolated var id: String { rawValue }
    nonisolated var label: String {
        switch self {
        case .omonaga: "VERTICAL"
        case .marugao: "SIDES"
        case .both: "BOTH"
        case .off: "OFF"
        }
    }
    nonisolated var detail: String {
        switch self {
        case .omonaga: "額・顎を引き締め"
        case .marugao: "頬の輪郭を引き締め"
        case .both: "上下＋頬の両方"
        case .off: "適用しない"
        }
    }
    nonisolated var targetPrefixes: [String] {
        switch self {
        case .omonaga: ["omonaga"]
        case .marugao: ["marugao"]
        case .both: ["omonaga", "marugao"]
        case .off: []
        }
    }
}

// 顔診断結果から各 preset のデフォルトを決める。
nonisolated enum MakeupPresetDefaults {
    nonisolated static func highlight(for shape: FaceShape?) -> HighlightPreset {
        switch shape ?? .tamago {
        case .tamago, .gyaku, .base: return .base
        case .marugao: return .marugao
        case .omonaga: return .omonaga
        }
    }
    nonisolated static func shadow(for shape: FaceShape?) -> ShadowPreset {
        switch shape ?? .tamago {
        case .tamago: return .both       // バランス顔は全体的に陰影
        case .marugao: return .marugao    // 丸顔は頬を引き締め
        case .omonaga: return .omonaga    // 面長は上下を引き締め
        case .gyaku: return .marugao      // 逆三角は頬の柔らかさを足す
        case .base: return .omonaga       // ベース型はエラを目立たなく上下を引き締め
        }
    }
}
