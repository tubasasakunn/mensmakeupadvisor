import Foundation

// 1つの化粧単位。
// メッシュベースの化粧 (highlight/shadow/eyeshadow/tearbag) は meshColors に
// meshID → 色 を持つ。base/eyeliner は単一色 tint、eyebrow は browType を使う。
nonisolated struct MakeupUnit: Sendable {
    var kind: MakeupKind
    var meshColors: [Int: MeshColor]
    var tint: MeshColor
    var browType: EyebrowApplier.BrowType?

    init(kind: MakeupKind,
         meshColors: [Int: MeshColor] = [:],
         tint: MeshColor = .clear,
         browType: EyebrowApplier.BrowType? = nil) {
        self.kind = kind
        self.meshColors = meshColors
        self.tint = tint
        self.browType = browType
    }

    // 実際に描画されるか。
    var isActive: Bool {
        switch kind {
        case .eyebrow:  return browType != nil && tint.isVisible
        case .eyeliner: return tint.isVisible
        case .base:     return tint.isVisible
        default:        return meshColors.values.contains(where: \.isVisible)
        }
    }

    // この unit が指定メッシュに乗せる色。
    func color(forMesh id: Int) -> MeshColor {
        kind.isMeshBased ? (meshColors[id] ?? .clear) : tint
    }

    // mesh ベース unit の代表的な強度 (全メッシュ最大の alpha)。
    var peakIntensity: Float {
        switch kind {
        case .eyebrow, .eyeliner, .base:
            return tint.a
        default:
            return meshColors.values.map(\.a).max() ?? 0
        }
    }

    // 指定メッシュ集合に一律の色を乗せた mesh ベース unit を作る。
    static func meshUniform(kind: MakeupKind,
                            meshIDs: some Sequence<Int>,
                            color: MeshColor) -> MakeupUnit {
        var map: [Int: MeshColor] = [:]
        for id in meshIDs { map[id] = color }
        return MakeupUnit(kind: kind, meshColors: map)
    }
}
