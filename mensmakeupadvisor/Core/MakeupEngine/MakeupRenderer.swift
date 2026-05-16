import CoreGraphics
import Foundation
import UIKit

// 化粧反映のオーケストレータ。
// `MakeupIntensity` (0-100 のレイヤー強度) を受け取り、`AppEnvironment` から
// 渡される FaceMesh を使って Highlight / Shadow / Base / Eye / Eyebrow を
// 順に重ねた最終画像を生成する。
//
// Python POC では各サブディレクトリの `main.py` が個別に呼ばれていたが、
// ここでは Studio 画面でリアルタイムにレイヤー強度を変更できるよう、
// 単一の関数で一括適用できる構造にしている。
nonisolated struct MakeupRenderer {
    nonisolated struct LayerSelection: Sendable {
        var highlightAreaNames: [String]   // target.json の "highlight" カテゴリ名
        var shadowAreaNames: [String]      // target.json の "shadow" カテゴリ名
        var applyBase: Bool
        var eyeAreaNames: [String]
        var applyEyeliner: Bool
        var eyebrowType: EyebrowApplier.BrowType

        // makeup_claude/loadmap/1-virtual-makeup/{1-1-highlight,1-2-shadow}/run_all.py
        // の PRESET_MAP に揃える。highlight/shadow とも prefix で target.json から
        // matching する POC のロジックそのままを Swift 側で再現する:
        //
        //   tamago (卵)   : highlight=base   shadow=なし
        //   marugao (丸顔) : highlight=marugao shadow=marugao
        //   omonaga (面長) : highlight=omonaga shadow=omonaga
        //   gyaku (逆三角) : highlight=base   shadow=なし
        //   base (ベース)  : highlight=base   shadow=なし
        //
        // 顔判定結果が手に入る前 (Studio 単独 Preview など) は tamago と同じ扱いに
        // する (PRESET_MAP の "base" 行に相当)。
        nonisolated static func forFaceShape(_ shape: FaceShape?) -> LayerSelection {
            let hlPrefix: String
            let shPrefix: String?
            switch shape ?? .tamago {
            case .tamago, .gyaku, .base:
                hlPrefix = "base"
                shPrefix = nil
            case .marugao:
                hlPrefix = "marugao"
                shPrefix = "marugao"
            case .omonaga:
                hlPrefix = "omonaga"
                shPrefix = "omonaga"
            }
            let highlightNames = MeshAreaLibrary
                .areas(category: .highlight, prefix: hlPrefix)
                .map(\.name)
            let shadowNames: [String]
            if let prefix = shPrefix {
                shadowNames = MeshAreaLibrary
                    .areas(category: .shadow, prefix: prefix)
                    .map(\.name)
            } else {
                shadowNames = []
            }
            return LayerSelection(
                highlightAreaNames: highlightNames,
                shadowAreaNames: shadowNames,
                applyBase: true,
                eyeAreaNames: ["eyeshadow_base", "eyeshadow_crease", "tear_bag", "lower_outer"],
                applyEyeliner: true,
                eyebrowType: .natural
            )
        }

        // Preview/Studio で顔判定結果が無い場合の既定値。tamago 相当 (=base prefix)。
        nonisolated static let `default` = LayerSelection(
            highlightAreaNames: ["base_t-zone", "base_c-zone", "base_under-eye"],
            shadowAreaNames: [],
            applyBase: true,
            eyeAreaNames: ["eyeshadow_base", "eyeshadow_crease", "tear_bag", "lower_outer"],
            applyEyeliner: true,
            eyebrowType: .natural
        )
    }

    // 0-100 を 0-1 に正規化する単純な変換
    private nonisolated static func normalize(_ value: Double) -> Float {
        Float(max(0.0, min(100.0, value)) / 100.0)
    }

    nonisolated static func render(image rawImage: UIImage, faceMesh: FaceMesh,
                       intensity: MakeupIntensity,
                       selection: LayerSelection = .default) -> UIImage {
        // CGImage は imageOrientation を持たないため、ここで .up に正規化しないと
        // 各 Applier の mask 座標がピクセル方向とユーザー方向で 90° ズレる。
        let image = rawImage.uprightOriented()
        // すべての intensity が 0 なら何も合成せずに元画像を返す（化粧 OFF）。
        // Studio 入場直後を「素の写真」として確実に見せるため。
        if intensity.base <= 0, intensity.highlight <= 0, intensity.shadow <= 0,
           intensity.eye <= 0, intensity.eyebrow <= 0 {
            return image
        }
        guard var current = image.safeCGImage else { return image }
        // 顔検出が失敗していて三角形が無い場合は元画像を返す
        guard !faceMesh.triangles.isEmpty else { return image }

        // 各レイヤーの強度は makeup_claude POC (run_all.py の --intensity default)
        // と完全一致させる。slider 100 で POC の default、50 で半分、と直感的に
        // 対応するようにする。
        //
        //   highlight : 0.12  (1-1-highlight/run_all.py default)
        //   shadow    : 0.25  (1-2-shadow/run_all.py default)
        //   base      : 0.30  (1-3-base/main.py default)
        //   eye       : 各エリア毎の AREA_DEFAULTS (eyeshadow_base=0.35 etc) × scale
        //   eyebrow   : 0.75  (DEFAULT_EYEBROW_INTENSITY)

        // 1.3 ベース (顔全体)
        if selection.applyBase, intensity.base > 0 {
            let opts = BaseApplier.Options(
                colorRGB: SIMD3<Float>(235, 200, 170),
                intensity: 0.30 * normalize(intensity.base)
            )
            if let out = BaseApplier.apply(image: current, faceMesh: faceMesh, options: opts) {
                current = out
            }
        }

        // 1.2 シャドウ
        if intensity.shadow > 0 {
            let scale = normalize(intensity.shadow)
            for name in selection.shadowAreaNames {
                guard let area = MeshAreaLibrary.lookup(category: .shadow, name: name) else { continue }
                // POC CLI default の RGB(139, 90, 43) (ブラウン) に揃える。
                // 関数 default の (90, 68, 50) は実利用されない値だった。
                let opts = ShadowApplier.Options(
                    meshIDs: area.meshIDs,
                    colorRGB: SIMD3<Float>(139, 90, 43),
                    intensity: 0.25 * scale
                )
                if let out = ShadowApplier.apply(image: current, faceMesh: faceMesh, options: opts) {
                    current = out
                }
            }
        }

        // 1.1 ハイライト
        if intensity.highlight > 0 {
            let scale = normalize(intensity.highlight)
            for name in selection.highlightAreaNames {
                guard let area = MeshAreaLibrary.lookup(category: .highlight, name: name) else { continue }
                let opts = HighlightApplier.Options(
                    meshIDs: area.meshIDs,
                    colorRGB: SIMD3<Float>(255, 255, 255),
                    intensity: 0.12 * scale
                )
                if let out = HighlightApplier.apply(image: current, faceMesh: faceMesh, options: opts) {
                    current = out
                }
            }
        }

        // 1.4 アイメイク
        if intensity.eye > 0 {
            let scale = normalize(intensity.eye)
            let (meshAreas, eyeliner) = EyeApplier.loadFromTargetJSON()
            for name in selection.eyeAreaNames {
                guard let area = meshAreas.first(where: { $0.name == name }),
                      var cfg = EyeApplier.defaultConfigs[name] else { continue }
                cfg = EyeApplier.AreaConfig(
                    name: cfg.name,
                    colorRGB: cfg.colorRGB,
                    intensity: cfg.intensity * scale,
                    blurScale: cfg.blurScale,
                    blend: cfg.blend
                )
                if let out = EyeApplier.applyMeshArea(image: current, faceMesh: faceMesh, meshIDs: area.meshIDs, config: cfg) {
                    current = out
                }
            }
            if selection.applyEyeliner, let data = eyeliner,
               var lineCfg = EyeApplier.defaultConfigs["eyeliner"] {
                lineCfg = EyeApplier.AreaConfig(
                    name: lineCfg.name,
                    colorRGB: lineCfg.colorRGB,
                    intensity: lineCfg.intensity * scale,
                    blurScale: lineCfg.blurScale,
                    blend: lineCfg.blend
                )
                if let out = EyeApplier.applyEyeliner(image: current, faceMesh: faceMesh, data: data, config: lineCfg) {
                    current = out
                }
            }
        }

        // 1.5 眉
        if intensity.eyebrow > 0 {
            let scale = normalize(intensity.eyebrow)
            let opts = EyebrowApplier.Options(
                type: selection.eyebrowType,
                colorRGB: SIMD3<Float>(85, 60, 45),
                intensity: 0.75 * scale,
                thicknessScale: 1.0,
                doErase: scale > 0.15,
                doDraw: scale > 0.0
            )
            if let out = EyebrowApplier.apply(image: current, faceMesh: faceMesh, options: opts) {
                current = out
            }
        }

        return UIImage(cgImage: current, scale: image.scale, orientation: image.imageOrientation)
    }
}
