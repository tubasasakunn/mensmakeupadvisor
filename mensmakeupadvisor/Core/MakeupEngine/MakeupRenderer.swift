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
        // の PRESET_MAP に基本準拠する。highlight は POC と完全一致。
        //
        //   tamago (卵)   : highlight=base
        //   marugao (丸顔) : highlight=marugao
        //   omonaga (面長) : highlight=omonaga
        //   gyaku (逆三角) : highlight=base
        //   base (ベース)  : highlight=base
        //
        // shadow は POC では face shape ごとに 1 preset だけだが、Studio FINE TUNE
        // のシャドウスライダーで「ガッツリ陰影を入れる」UX を成立させるため、
        // どの顔型でも omonaga (顎下) + marugao (頬の輪郭) を併用する。これで
        // 顔の上下と左右両方に陰が乗り、視認性が高くなる。
        nonisolated static func forFaceShape(_ shape: FaceShape?) -> LayerSelection {
            let hlPrefix: String
            switch shape ?? .tamago {
            case .tamago, .gyaku, .base: hlPrefix = "base"
            case .marugao:               hlPrefix = "marugao"
            case .omonaga:               hlPrefix = "omonaga"
            }
            let highlightNames = MeshAreaLibrary
                .areas(category: .highlight, prefix: hlPrefix)
                .map(\.name)
            // 全顔型で omonaga + marugao の両方を適用 (univeral contouring)
            let shadowNames = MeshAreaLibrary.areas(category: .shadow, prefix: "omonaga").map(\.name)
                + MeshAreaLibrary.areas(category: .shadow, prefix: "marugao").map(\.name)
            return LayerSelection(
                highlightAreaNames: highlightNames,
                shadowAreaNames: shadowNames,
                applyBase: true,
                eyeAreaNames: ["eyeshadow_base", "eyeshadow_crease", "tear_bag", "lower_outer"],
                applyEyeliner: true,
                eyebrowType: .natural
            )
        }

        // Preview/Studio で顔判定結果が無い場合の既定値。tamago と同じ扱い。
        nonisolated static let `default` = LayerSelection(
            highlightAreaNames: ["base_t-zone", "base_c-zone", "base_under-eye"],
            shadowAreaNames: ["omonaga-upper", "omonaga-lower", "marugao-side"],
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

    // Studio 表示では UIImage を 4:5 で約 320pt × 400pt 表示 = 3x で 1200x600
    // 程度しか必要ない。それより大きい入力画像はピクセル単位の compositing /
    // GaussianBlur がボトルネックになりリアルタイム反映できないため、
    // 内部処理用にここまで縮小する。
    private nonisolated static let maxWorkWidth = 800

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
        guard let srcCG = image.safeCGImage else { return image }
        // 顔検出が失敗していて三角形が無い場合は元画像を返す
        guard !faceMesh.triangles.isEmpty else { return image }

        // ── 入力画像が大きい場合は内部処理だけ縮小して走らせる。landmarks は
        // 正規化 0-1 で持っているので、どの解像度でも mask の幾何は同じ位置に
        // 一致する。Studio 画面の表示にはこの縮小サイズで十分。
        var current: CGImage = srcCG
        if srcCG.width > maxWorkWidth {
            if let downsized = downsample(image: srcCG, targetWidth: maxWorkWidth) {
                current = downsized
            }
        }

        // 強度マッピング: slider 100 = POC default の 2x (UI で派手にいじったときに
        // 「ガッツリ盛った」見た目になる)、slider 50 で POC default 相当、と
        // 直感的に対応させる。色や合成式 (alpha_composite_*) はすべて POC 完全
        // 一致のままで、倍率だけ UI 用に底上げする。
        //
        //   highlight : 0.12 × 2 = 0.24 × scale  (POC default = scale=0.5 相当)
        //   shadow    : 0.25 × 2 = 0.50 × scale
        //   base      : 0.30 × 2 = 0.60 × scale
        //   eye       : 各エリア AREA_DEFAULTS × scale (元から POC 強め)
        //   eyebrow   : 0.75 × scale (POC default)

        // 1.3 ベース (顔全体)
        if selection.applyBase, intensity.base > 0 {
            let opts = BaseApplier.Options(
                colorRGB: SIMD3<Float>(235, 200, 170),
                intensity: 0.60 * normalize(intensity.base)
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
                // 関数 default の (90, 68, 50) は CLI 経由では使われない値だった。
                let opts = ShadowApplier.Options(
                    meshIDs: area.meshIDs,
                    colorRGB: SIMD3<Float>(139, 90, 43),
                    intensity: 0.50 * scale
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
                    intensity: 0.24 * scale
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

    // 高速処理のための縮小コピー。 CGImage は scale 情報を持たないので
    // CGContext で targetWidth × (h/w × targetWidth) 比率にレンダリングする。
    private nonisolated static func downsample(image: CGImage, targetWidth: Int) -> CGImage? {
        let w = image.width
        let h = image.height
        guard w > targetWidth else { return image }
        let tw = targetWidth
        let th = Int(Double(h) * Double(tw) / Double(w))
        let bytesPerRow = tw * 4
        let info: CGBitmapInfo = [
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            CGBitmapInfo.byteOrder32Big,
        ]
        guard let ctx = CGContext(
            data: nil,
            width: tw,
            height: th,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: info.rawValue
        ) else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: tw, height: th))
        return ctx.makeImage()
    }
}
