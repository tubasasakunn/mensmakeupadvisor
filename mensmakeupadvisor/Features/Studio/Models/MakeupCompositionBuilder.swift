import Foundation

// target.json の area / 顔型デフォルト / SavedLook から MakeupComposition を組む。
// mesh ベース unit には対象 area の mesh ID をすべて埋め、alpha で強度を表す。
nonisolated enum MakeupCompositionBuilder {

    // 顔型に応じた既定 composition。各 unit のメッシュは埋めるが強度 0 (素の状態)。
    static func makeDefault(for shape: FaceShape?) -> MakeupComposition {
        make(
            highlightAreas: MakeupAreaDefaults.highlight(for: shape),
            shadowAreas: MakeupAreaDefaults.shadow(for: shape),
            eyeAreas: MakeupAreaDefaults.eye(for: shape),
            browType: nil,
            base: 0, highlight: 0, shadow: 0, eye: 0
        )
    }

    // area 集合 + 各化粧の強度 (0–1) から composition を組む。
    static func make(highlightAreas: Set<String>,
                     shadowAreas: Set<String>,
                     eyeAreas: Set<String>,
                     browType: EyebrowApplier.BrowType?,
                     base: Float,
                     highlight: Float,
                     shadow: Float,
                     eye: Float) -> MakeupComposition {
        var comp = MakeupComposition()

        comp.setUnit(MakeupUnit(kind: .base, tint: MakeupKind.base.color(intensity: base)))

        comp.setUnit(MakeupUnit.meshUniform(
            kind: .highlight,
            meshIDs: meshIDs(.highlight, names: highlightAreas),
            color: MakeupKind.highlight.color(intensity: highlight)))

        comp.setUnit(MakeupUnit.meshUniform(
            kind: .shadow,
            meshIDs: meshIDs(.shadow, names: shadowAreas),
            color: MakeupKind.shadow.color(intensity: shadow)))

        comp.setUnit(MakeupUnit.meshUniform(
            kind: .eyeshadow,
            meshIDs: eyeMeshIDs(kind: .eyeshadow, names: eyeAreas),
            color: MakeupKind.eyeshadow.color(intensity: eye)))

        comp.setUnit(MakeupUnit.meshUniform(
            kind: .tearbag,
            meshIDs: eyeMeshIDs(kind: .tearbag, names: eyeAreas),
            color: MakeupKind.tearbag.color(intensity: eye)))

        comp.setUnit(MakeupUnit(
            kind: .eyeliner,
            tint: MakeupKind.eyeliner.color(intensity: eyeAreas.contains("eyeliner") ? eye : 0)))

        var brow = MakeupUnit(kind: .eyebrow, tint: MakeupKind.eyebrow.color(intensity: 1))
        brow.browType = browType
        comp.setUnit(brow)

        return comp
    }

    // MARK: - target.json lookup

    // highlight / shadow カテゴリの対象 area の mesh ID。
    static func meshIDs(_ category: MeshAreaCategory, names: some Sequence<String>) -> [Int] {
        let nameSet = Set(names)
        var ids: [Int] = []
        for area in MeshAreaLibrary.load(category: category) where nameSet.contains(area.name) {
            ids.append(contentsOf: area.meshIDs)
        }
        return ids
    }

    // eye カテゴリのうち、その化粧単位 (eyeshadow / tearbag) に属する area の mesh ID。
    static func eyeMeshIDs(kind: MakeupKind, names: some Sequence<String>) -> [Int] {
        let nameSet = Set(names)
        let (meshAreas, _) = EyeApplier.loadFromTargetJSON()
        var ids: [Int] = []
        for area in meshAreas
        where nameSet.contains(area.name) && MakeupKind.eyeKind(forArea: area.name) == kind {
            ids.append(contentsOf: area.meshIDs)
        }
        return ids
    }

    // MARK: - composition → area name (SavedLook 保存用)

    // その化粧単位が触れている area 名。SavedLook のサムネ表示に使う。
    static func coveredAreaNames(_ category: MeshAreaCategory, unit: MakeupUnit?) -> Set<String> {
        guard let unit else { return [] }
        let active = Set(unit.meshColors.filter { $0.value.isVisible }.keys)
        guard !active.isEmpty else { return [] }
        let areas = category == .eye
            ? EyeApplier.loadFromTargetJSON().mesh
            : MeshAreaLibrary.load(category: category)
        var names: Set<String> = []
        for area in areas where !active.isDisjoint(with: Set(area.meshIDs)) {
            names.insert(area.name)
        }
        return names
    }
}
