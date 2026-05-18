import Foundation

// 1つの化粧単位。mesh ベースの化粧は meshColors に meshID → 色 を持つ。
// base は全メッシュ分の色を持ち、eyebrow は mesh ではなく browType を使う。
nonisolated struct MakeupUnit: Sendable {
    var kind: MakeupKind
    var meshColors: [Int: MeshColor]
    var browType: EyebrowApplier.BrowType?

    init(kind: MakeupKind,
         meshColors: [Int: MeshColor] = [:],
         browType: EyebrowApplier.BrowType? = nil) {
        self.kind = kind
        self.meshColors = meshColors
        self.browType = browType
    }

    // 実際に描画されるか (alpha>0 のメッシュ、または眉タイプ選択あり)。
    var isActive: Bool {
        if kind == .eyebrow { return browType != nil }
        return meshColors.values.contains(where: \.isVisible)
    }

    // 指定メッシュ集合に一律の色を乗せた unit を作る。
    static func uniform(kind: MakeupKind,
                        meshIDs: some Sequence<Int>,
                        color: MeshColor) -> MakeupUnit {
        var map: [Int: MeshColor] = [:]
        for id in meshIDs { map[id] = color }
        return MakeupUnit(kind: kind, meshColors: map)
    }
}
