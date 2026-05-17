import CoreGraphics
import Foundation

// 1.4 アイメイク
// makeup_claude/loadmap/1-virtual-makeup/1-4-eye/main.py の `apply_eye_area` /
// `build_eyeliner_mask` を移植。
//
//   - eyeshadow_base / eyeshadow_crease / tear_bag / lower_outer:
//       メッシュ ID ベース。マスクを Gaussian で柔らかくし、エリアごとに合成方式を選ぶ
//   - eyeliner:
//       upper/lower のランドマーク列に沿ったポリラインを目の外側へオフセットして描画
nonisolated enum EyeApplier {
    nonisolated enum Blend: String, Sendable { case normal, multiply, additive }

    nonisolated struct AreaConfig: Sendable {
        var name: String
        var colorRGB: SIMD3<Float>
        var intensity: Float
        var blurScale: Float
        var blend: Blend
    }

    nonisolated struct EyelinerData: Sendable {
        var upperRight: [Int]
        var upperLeft: [Int]
        var lowerRight: [Int]
        var lowerLeft: [Int]
        var thickness: Double   // base thickness param
        var thicknessScale: Float = 0.2
    }

    // Python `AREA_DEFAULTS` のデフォルト
    nonisolated static let defaultConfigs: [String: AreaConfig] = [
        "eyeshadow_base":   .init(name: "eyeshadow_base",   colorRGB: SIMD3<Float>(190, 145, 120), intensity: 0.35, blurScale: 0.8, blend: .normal),
        "eyeshadow_crease": .init(name: "eyeshadow_crease", colorRGB: SIMD3<Float>(160, 110, 85),  intensity: 0.25, blurScale: 0.5, blend: .normal),
        "eyeliner":         .init(name: "eyeliner",         colorRGB: SIMD3<Float>(35, 20, 10),    intensity: 0.55, blurScale: 0.3, blend: .normal),
        "tear_bag":         .init(name: "tear_bag",         colorRGB: SIMD3<Float>(255, 230, 215), intensity: 0.12, blurScale: 0.5, blend: .additive),
        "lower_outer":      .init(name: "lower_outer",      colorRGB: SIMD3<Float>(180, 100, 85),  intensity: 0.18, blurScale: 0.3, blend: .normal),
    ]

    // メッシュ ID 系
    nonisolated static func applyMeshArea(image: CGImage, faceMesh: FaceMesh,
                              meshIDs: [Int], config: AreaConfig) -> CGImage? {
        let w = image.width
        let h = image.height
        let mask = faceMesh.buildMask(meshIDs: meshIDs, width: w, height: h)
        let soft = FloatBuffer.fromMask(mask)
        let top = faceMesh.landmark(FaceLandmarkID.foreheadTop, width: w, height: h)
        let chin = faceMesh.landmark(FaceLandmarkID.chinBottom, width: w, height: h)
        let faceH = max(1.0, hypot(top.x - chin.x, top.y - chin.y))
        let ksize = Int(Double(faceH) * 0.03 * Double(config.blurScale))
        GaussianBlur.apply(soft, ksize: ksize)
        return composite(image: image, mask: soft, color: config.colorRGB, intensity: config.intensity, blend: config.blend)
    }

    // アイライナー (ポリライン)
    nonisolated static func applyEyeliner(image: CGImage, faceMesh: FaceMesh,
                              data: EyelinerData, config: AreaConfig) -> CGImage? {
        let w = image.width
        let h = image.height
        let mask = MaskBuffer(width: w, height: h)
        guard let ctx = CGContext(
            data: mask.dataPointer,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return image }
        // landmark 座標は画像座標(Y-DOWN)。CGContext は Y-UP なので CTM を反転して
        // 画像座標で stroke を描けるようにする (詳細は FaceMesh.buildMask のコメント参照)。
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)

        let templeR = faceMesh.landmark(FaceLandmarkID.templeR, width: w, height: h)
        let templeL = faceMesh.landmark(FaceLandmarkID.templeL, width: w, height: h)
        let faceWPx = abs(templeR.x - templeL.x)
        let thickness = max(2.0, Double(faceWPx) * 0.012 * data.thickness * Double(data.thicknessScale))
        let offsetPx = thickness / 2 + 1

        ctx.setStrokeColor(gray: 1.0, alpha: 1.0)
        ctx.setLineWidth(CGFloat(thickness))
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        let sides: [(upper: [Int], lower: [Int])] = [
            (data.upperRight, data.lowerRight),
            (data.upperLeft, data.lowerLeft),
        ]

        for side in sides {
            let allIDs = side.upper + side.lower
            let validIDs = allIDs.filter { faceMesh.points.indices.contains($0) }
            guard !validIDs.isEmpty else { continue }
            let cx = validIDs.map { Double(faceMesh.landmark($0, width: w, height: h).x) }.reduce(0, +) / Double(validIDs.count)
            let cy = validIDs.map { Double(faceMesh.landmark($0, width: w, height: h).y) }.reduce(0, +) / Double(validIDs.count)

            for landmarkIDs in [side.upper, side.lower] {
                var pts: [CGPoint] = []
                for lid in landmarkIDs where faceMesh.points.indices.contains(lid) {
                    let lp = faceMesh.landmark(lid, width: w, height: h)
                    var px = Double(lp.x)
                    var py = Double(lp.y)
                    let dx = px - cx
                    let dy = py - cy
                    let len = max(sqrt(dx * dx + dy * dy), 1e-6)
                    px += dx / len * offsetPx
                    py += dy / len * offsetPx
                    pts.append(CGPoint(x: px, y: py))
                }
                guard pts.count >= 2 else { continue }
                ctx.beginPath()
                ctx.move(to: pts[0])
                for i in 1..<pts.count {
                    ctx.addLine(to: pts[i])
                }
                ctx.strokePath()
            }
        }

        let soft = FloatBuffer.fromMask(mask)
        let top = faceMesh.landmark(FaceLandmarkID.foreheadTop, width: w, height: h)
        let chin = faceMesh.landmark(FaceLandmarkID.chinBottom, width: w, height: h)
        let faceH = max(1.0, hypot(top.x - chin.x, top.y - chin.y))
        let ksize = Int(Double(faceH) * 0.03 * Double(config.blurScale))
        GaussianBlur.apply(soft, ksize: ksize)
        return composite(image: image, mask: soft, color: config.colorRGB, intensity: config.intensity, blend: config.blend)
    }

    // MARK: - private
    private nonisolated static func composite(image: CGImage, mask: FloatBuffer,
                                  color: SIMD3<Float>, intensity: Float, blend: Blend) -> CGImage? {
        switch blend {
        case .normal:   return Compositing.normal(image: image, mask: mask, color: color, intensity: intensity)
        case .multiply: return Compositing.multiply(image: image, mask: mask, color: color, intensity: intensity)
        case .additive: return Compositing.additive(image: image, mask: mask, color: color, intensity: intensity)
        }
    }

    // target.json の eye カテゴリから (meshAreas, eyelinerData) を切り出す
    nonisolated static func loadFromTargetJSON(bundle: Bundle = .main) -> (mesh: [MeshArea], eyeliner: EyelinerData?) {
        guard let url = bundle.url(forResource: "target", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["eye"] as? [[String: Any]]
        else {
            return ([], nil)
        }
        var meshAreas: [MeshArea] = []
        var eyeliner: EyelinerData?
        for entry in entries {
            guard let name = entry["name"] as? String else { continue }
            if (entry["type"] as? String) == "polyline" {
                guard let upper = entry["upper_landmarks"] as? [String: [Int]],
                      let lower = entry["lower_landmarks"] as? [String: [Int]],
                      let thickness = entry["thickness"] as? Double
                else { continue }
                _ = name
                eyeliner = EyelinerData(
                    upperRight: upper["right"] ?? [],
                    upperLeft: upper["left"] ?? [],
                    lowerRight: lower["right"] ?? [],
                    lowerLeft: lower["left"] ?? [],
                    thickness: thickness
                )
            } else {
                let ids: [Int]
                if let flat = entry["mesh_id"] as? [Int] {
                    ids = flat
                } else if let nested = entry["mesh_id"] as? [[Int]], let inner = nested.first {
                    ids = inner
                } else {
                    continue
                }
                meshAreas.append(MeshArea(name: name, meshIDs: ids))
            }
        }
        return (meshAreas, eyeliner)
    }
}
