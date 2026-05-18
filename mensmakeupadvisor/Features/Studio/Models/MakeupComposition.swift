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

    // MARK: - Mutation

    mutating func setUnit(_ unit: MakeupUnit) {
        units[unit.kind] = unit
    }

    mutating func removeUnit(_ kind: MakeupKind) {
        units[kind] = nil
    }

    mutating func setColor(_ color: MeshColor, meshID: Int, kind: MakeupKind) {
        var unit = units[kind] ?? MakeupUnit(kind: kind)
        unit.meshColors[meshID] = color
        units[kind] = unit
    }

    // MARK: - Combined color

    // メッシュごとの「合計した色」: render 順に全 unit の色を重ねる。
    func combinedColor(forMesh id: Int) -> MeshColor {
        var result = MeshColor.clear
        for unit in orderedUnits {
            if let color = unit.meshColors[id], color.isVisible {
                result = color.composited(over: result)
            }
        }
        return result
    }

    // どこかの unit が色を乗せている全メッシュの合計色マップ。
    // メッシュサムネ表示・状態確認に使う。
    func combinedColorMap() -> [Int: MeshColor] {
        var ids: Set<Int> = []
        for unit in units.values { ids.formUnion(unit.meshColors.keys) }
        var map: [Int: MeshColor] = [:]
        for id in ids {
            let color = combinedColor(forMesh: id)
            if color.isVisible { map[id] = color }
        }
        return map
    }
}
