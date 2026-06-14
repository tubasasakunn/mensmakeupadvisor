import CoreGraphics
import Foundation
import UIKit

// 化粧反映のオーケストレータ。
// `MakeupComposition` (化粧単位の集合) を受け取り、各 unit を render 順に
// 該当 Applier へ流して最終画像を生成する。
nonisolated struct MakeupRenderer {
    // Studio 表示には大きすぎる入力画像を内部処理用に縮小する閾値。
    private nonisolated static let maxWorkWidth = 800

    nonisolated static func render(image rawImage: UIImage, faceMesh: FaceMesh,
                                   composition: MakeupComposition) -> UIImage {
        // CGImage は imageOrientation を持たないため .up に正規化する。
        let image = rawImage.uprightOriented()

        let activeUnits = composition.orderedUnits.filter { $0.isActive }
        // 化粧が無ければ素の画像をそのまま返す。
        if activeUnits.isEmpty { return image }
        guard let srcCG = image.safeCGImage else { return image }
        guard !faceMesh.triangles.isEmpty else { return image }

        var current: CGImage = srcCG
        if srcCG.width > maxWorkWidth,
           let downsized = downsample(image: srcCG, targetWidth: maxWorkWidth) {
            current = downsized
        }

        // 肌マスク (髪・眉・唇・目を除外) は base/highlight/shadow が
        // 1 つでも有効なときだけ生成して共有する。
        let needsSkinMask = activeUnits.contains {
            $0.kind == .base || $0.kind == .highlight || $0.kind == .shadow
        }
        let skinMask: FloatBuffer? = needsSkinMask
            ? SkinMask.build(image: current, faceMesh: faceMesh)
            : nil

        for unit in activeUnits {
            if let out = apply(unit: unit, to: current, faceMesh: faceMesh, skinMask: skinMask) {
                current = out
            }
        }

        return UIImage(cgImage: current, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Per-unit

    private nonisolated static func apply(unit: MakeupUnit, to image: CGImage,
                                          faceMesh: FaceMesh, skinMask: FloatBuffer?) -> CGImage? {
        let gain = unit.kind.renderGain
        switch unit.kind {
        case .base:
            let opts = BaseApplier.Options(
                colorRGB: unit.tint.simd,
                intensity: gain * unit.tint.a
            )
            return BaseApplier.apply(image: image, faceMesh: faceMesh, options: opts, skinMask: skinMask)

        case .highlight:
            var current = image
            for (color, ids) in groupByColor(unit) {
                let opts = HighlightApplier.Options(
                    meshIDs: ids,
                    colorRGB: color.simd,
                    intensity: gain * color.a
                )
                if let out = HighlightApplier.apply(image: current, faceMesh: faceMesh,
                                                    options: opts, skinMask: skinMask) {
                    current = out
                }
            }
            return current

        case .shadow:
            var current = image
            for (color, ids) in groupByColor(unit) {
                let opts = ShadowApplier.Options(
                    meshIDs: ids,
                    colorRGB: color.simd,
                    intensity: gain * color.a
                )
                if let out = ShadowApplier.apply(image: current, faceMesh: faceMesh,
                                                 options: opts, skinMask: skinMask) {
                    current = out
                }
            }
            return current

        case .eyeshadow, .tearbag:
            var current = image
            let blend: EyeApplier.Blend = unit.kind == .tearbag ? .additive : .normal
            let blurScale: Float = unit.kind == .tearbag ? 0.5 : 0.8
            for (color, ids) in groupByColor(unit) {
                let config = EyeApplier.AreaConfig(
                    name: unit.kind.rawValue,
                    colorRGB: color.simd,
                    intensity: gain * color.a,
                    blurScale: blurScale,
                    blend: blend
                )
                if let out = EyeApplier.applyMeshArea(image: current, faceMesh: faceMesh,
                                                      meshIDs: ids, config: config) {
                    current = out
                }
            }
            return current

        case .eyeliner:
            let (_, eyeliner) = EyeApplier.loadFromTargetJSON()
            guard let data = eyeliner, unit.tint.a > 0 else { return image }
            let config = EyeApplier.AreaConfig(
                name: "eyeliner",
                colorRGB: unit.tint.simd,
                intensity: gain * unit.tint.a,
                blurScale: 0.3,
                blend: .normal
            )
            return EyeApplier.applyEyeliner(image: image, faceMesh: faceMesh, data: data, config: config)

        case .eyebrow:
            guard let type = unit.browType else { return image }
            let scale = max(unit.tint.a, 0.0)
            let opts = EyebrowApplier.Options(
                type: type,
                colorRGB: unit.tint.simd,
                intensity: gain * scale,
                thicknessScale: 1.0,
                doErase: scale > 0.15,
                doDraw: scale > 0.0
            )
            return EyebrowApplier.apply(image: image, faceMesh: faceMesh, options: opts)
        }
    }

    // mesh ベース unit の meshColors を同色ごとにまとめる。
    // 同じ色のメッシュは 1 回の Applier 呼び出しで処理できる。
    private nonisolated static func groupByColor(_ unit: MakeupUnit) -> [MeshColor: [Int]] {
        var groups: [MeshColor: [Int]] = [:]
        for (id, color) in unit.meshColors where color.isVisible {
            groups[color, default: []].append(id)
        }
        return groups
    }

    // MARK: - Downsample

    private nonisolated static func downsample(image: CGImage, targetWidth: Int) -> CGImage? {
        let w = image.width
        let h = image.height
        guard w > targetWidth else { return image }
        let tw = targetWidth
        // 極端な横長画像では Int 丸めで高さが 0 になり CGContext 生成が失敗する。
        let th = max(1, Int(Double(h) * Double(tw) / Double(w)))
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
