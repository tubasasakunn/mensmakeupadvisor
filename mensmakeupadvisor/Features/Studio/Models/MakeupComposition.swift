import Foundation

// Studio が持つ唯一の化粧状態。化粧単位 (MakeupUnit) の集合で、
// 旧 MakeupIntensity + highlightAreas/shadowAreas/eyeAreas + eyebrowType を
// すべて置き換える。各メッシュの「合計した色」はここから派生して求める。
nonisolated struct MakeupComposition: Sendable {
    // kind ごとに 1 unit。
    var units: [MakeupKind: MakeupUnit]

    init(units: [MakeupKind: MakeupUnit] = [:]) {
        self.units = units
    }

    static let empty = MakeupComposition()

    // 合成順 (renderOrder 昇順) に並べた unit。
    var orderedUnits: [MakeupUnit] {
        units.values.sorted { $0.kind.renderOrder < $1.kind.renderOrder }
    }

    func unit(_ kind: MakeupKind) -> MakeupUnit? { units[kind] }

    var browType: EyebrowApplier.BrowType? { units[.eyebrow]?.browType }

    // MARK: - Mutation

    mutating func setUnit(_ unit: MakeupUnit) {
        units[unit.kind] = unit
    }

    // その化粧単位の代表強度 (0–1)。FINE TUNE スライダーの表示値。
    func intensity(of kind: MakeupKind) -> Float {
        units[kind]?.peakIntensity ?? 0
    }

    // その化粧単位の全メッシュ (mesh ベース) / tint に一律の強度を適用する。
    mutating func setIntensity(_ value: Float, for kind: MakeupKind) {
        let v = max(0, min(1, value))
        if kind.isMeshBased {
            guard var unit = units[kind] else { return }
            for (id, color) in unit.meshColors {
                unit.meshColors[id] = color.withIntensity(v)
            }
            units[kind] = unit
        } else {
            var unit = units[kind] ?? MakeupUnit(kind: kind)
            unit.tint = kind.color(intensity: v)
            units[kind] = unit
        }
    }

    mutating func setBrowType(_ type: EyebrowApplier.BrowType?) {
        var unit = units[.eyebrow] ?? MakeupUnit(kind: .eyebrow)
        unit.browType = type
        if type != nil, !unit.tint.isVisible {
            unit.tint = MakeupKind.eyebrow.color(intensity: 1)
        }
        units[.eyebrow] = unit
    }

    // MARK: - Combined color

    // メッシュごとの「合計した色」: render 順に全 unit の色を重ねる。
    // base は全メッシュに一律 (tint)、eyeliner/eyebrow は mesh を持たない。
    func combinedColor(forMesh id: Int) -> MeshColor {
        var result = MeshColor.clear
        for unit in orderedUnits {
            let color: MeshColor = switch unit.kind {
            case .base:                                     unit.tint
            case .highlight, .shadow, .eyeshadow, .tearbag: unit.meshColors[id] ?? .clear
            case .eyeliner, .eyebrow:                       .clear
            }
            if color.isVisible {
                result = color.composited(over: result)
            }
        }
        return result
    }

    // mesh ベース unit が色を乗せている全メッシュの合計色マップ。
    func combinedColorMap() -> [Int: MeshColor] {
        var ids: Set<Int> = []
        for unit in units.values where unit.kind.isMeshBased {
            ids.formUnion(unit.meshColors.keys)
        }
        var map: [Int: MeshColor] = [:]
        for id in ids {
            let color = combinedColor(forMesh: id)
            if color.isVisible { map[id] = color }
        }
        return map
    }
}
