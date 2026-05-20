import Foundation
import SwiftUI

// SavedLook の化粧を、直近診断の facemesh 上に「実際の mesh ID」で重ねて描く。
// 化粧領域は target.json の mesh ID (= 細分化三角形 index) で定義され、色と
// 不透明度は MakeupKind から算出する。顔写真は使わず Canvas でプログラム描画。
// ファンデーション (素肌ベース) は顔全体に及ぶためサムネでは描かない。
struct SavedLookMeshDrawer {
    var context: GraphicsContext
    let size: CGSize
    let look: SavedLook
    let geometry: SavedLookMeshGeometry?

    private let meshColor = Theme.Mesh.savedLookOverlay

    func draw() {
        drawBackground()
        guard let geometry,
              let layout = MeshLayout(points: geometry.points,
                                      aspect: geometry.imageAspect, size: size) else {
            drawPlaceholder()
            return
        }
        drawWireframe(layout)
        // renderOrder 順: shadow → highlight → eyeshadow → tearbag → eyeliner → brow
        drawMakeup(layout, triangles: geometry.triangles)
    }

    // MARK: - Background / Placeholder

    private func drawBackground() {
        var ctx = context
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .color(Theme.Mesh.backdrop))
    }

    // メッシュ未取得 (診断前に保存されたルック等) のフォールバック。
    private func drawPlaceholder() {
        var ctx = context
        let cols = 8, rows = 10
        for c in 0...cols {
            var p = Path()
            let x = CGFloat(c) * size.width / CGFloat(cols)
            p.move(to: CGPoint(x: x, y: 0))
            p.addLine(to: CGPoint(x: x, y: size.height))
            ctx.stroke(p, with: .color(Theme.Mesh.wireSubtle), lineWidth: 0.5)
        }
        for r in 0...rows {
            var p = Path()
            let y = CGFloat(r) * size.height / CGFloat(rows)
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: size.width, y: y))
            ctx.stroke(p, with: .color(Theme.Mesh.wireSubtle), lineWidth: 0.5)
        }
    }

    // MARK: - Mesh wireframe

    private func drawWireframe(_ layout: MeshLayout) {
        var ctx = context
        let edges = FaceMeshResources.tesselationConnections()
        guard !edges.isEmpty else { return }
        var path = Path()
        for (a, b) in edges where layout.pts.indices.contains(a) && layout.pts.indices.contains(b) {
            path.move(to: layout.pts[a])
            path.addLine(to: layout.pts[b])
        }
        ctx.stroke(path, with: .color(meshColor), lineWidth: 0.3)
    }

    // MARK: - Makeup

    private func drawMakeup(_ layout: MeshLayout, triangles: [(Int, Int, Int)]) {
        var ctx = context

        fillTriangles(&ctx, layout, triangles,
                      ids: SavedLookMeshLibrary.shadowIDs(look.shadowAreaSet),
                      kind: .shadow, intensity: look.shadow)

        fillTriangles(&ctx, layout, triangles,
                      ids: SavedLookMeshLibrary.highlightIDs(look.highlightAreaSet),
                      kind: .highlight, intensity: look.highlight)

        fillTriangles(&ctx, layout, triangles,
                      ids: SavedLookMeshLibrary.eyeshadowIDs(look.eyeAreaSet),
                      kind: .eyeshadow, intensity: look.eye)

        fillTriangles(&ctx, layout, triangles,
                      ids: SavedLookMeshLibrary.tearbagIDs(look.eyeAreaSet),
                      kind: .tearbag, intensity: look.eye)

        drawEyeliner(&ctx, layout)

        if let raw = look.eyebrowTypeRaw, !raw.isEmpty {
            fillTriangles(&ctx, layout, triangles,
                          ids: SavedLookMeshLibrary.eyebrowFullIDs(),
                          kind: .eyebrow, intensity: look.eyebrow)
        }
    }

    private func fillTriangles(_ ctx: inout GraphicsContext, _ layout: MeshLayout,
                               _ triangles: [(Int, Int, Int)], ids: [Int],
                               kind: MakeupKind, intensity: Double) {
        let alpha = makeupAlpha(intensity)
        guard !ids.isEmpty, alpha > 0 else { return }
        var path = Path()
        for id in ids where triangles.indices.contains(id) {
            let (a, b, c) = triangles[id]
            guard layout.pts.indices.contains(a),
                  layout.pts.indices.contains(b),
                  layout.pts.indices.contains(c) else { continue }
            path.move(to: layout.pts[a])
            path.addLine(to: layout.pts[b])
            path.addLine(to: layout.pts[c])
            path.closeSubpath()
        }
        // 実際の Applier と同じく化粧をぼかす。三角形のベタ塗りでは出ない
        // 「パウダーが肌に溶けた柔らかい縁」を再現する。ぼかし量は Applier の
        // Gaussian カーネル (顔の高さ基準) に合わせて化粧ごとに変える。
        var blurred = ctx
        blurred.addFilter(.blur(radius: blurRadius(kind, faceH: layout.faceH)))
        blurred.fill(path, with: .color(makeupColor(kind, alpha: alpha)))
    }

    // アイラインは mesh 領域ではなく目際のランドマークを結ぶポリライン。
    private func drawEyeliner(_ ctx: inout GraphicsContext, _ layout: MeshLayout) {
        guard look.eyeAreaSet.contains("eyeliner"),
              let data = SavedLookMeshLibrary.eyeliner() else { return }
        // 細い不透明ラインなので、暗背景でも視認できるよう下限を設ける。
        let alpha = max(0.55, makeupAlpha(look.eye))
        let color = makeupColor(.eyeliner, alpha: alpha)
        let width = max(0.9, layout.faceW * 0.013)
        // アイラインは輪郭をぼかす実手順 (blurScale 0.3) に合わせ、ごく薄くだけ
        // ぼかす。線として視認できる程度のシャープさは保つ。
        var blurred = ctx
        blurred.addFilter(.blur(radius: blurRadius(.eyeliner, faceH: layout.faceH)))
        for indices in [data.upperRight, data.upperLeft] {
            let pts = indices.compactMap { layout.pts.indices.contains($0) ? layout.pts[$0] : nil }
            guard pts.count >= 2 else { continue }
            var path = Path()
            path.move(to: pts[0])
            for p in pts.dropFirst() { path.addLine(to: p) }
            blurred.stroke(path, with: .color(color),
                           style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - Color

    // 強度 (0-100) を不透明度へ。1.0 まで上げると平面塗りが単色のベタになるため
    // 上限を 0.9 に抑える。
    private func makeupAlpha(_ intensity: Double) -> Double {
        min(0.9, max(0, intensity / 100))
    }

    // Applier の Gaussian ブラー量 (faceH 基準) をサムネ座標へ写したぼかし半径。
    // highlight / shadow は 2 段ブラーで広く溶かし、eye 系は 1 段で控えめ、
    // eyeliner は線を残すため最小限。
    private func blurRadius(_ kind: MakeupKind, faceH: CGFloat) -> CGFloat {
        let scale: CGFloat = switch kind {
        case .highlight:      0.05
        case .shadow:         0.06
        case .eyeshadow:      0.025
        case .tearbag:        0.018
        case .eyebrow:        0.02
        case .eyeliner:       0.01
        case .base:           0.03
        }
        return faceH * scale
    }

    private func makeupColor(_ kind: MakeupKind, alpha: Double) -> Color {
        let c = kind.defaultColor
        return Color(.sRGB,
                     red: Double(c.r) / 255,
                     green: Double(c.g) / 255,
                     blue: Double(c.b) / 255,
                     opacity: alpha)
    }
}

// MARK: - MeshLayout

// 細分化メッシュの正規化頂点をサムネイル座標へ写像する。
// x は画像幅、y は画像高さで個別に正規化されているため、aspect (= 幅/高さ) を
// x に乗じて実寸比へ戻し、顔が横に潰れる歪みを解消する。
private struct MeshLayout {
    let pts: [CGPoint]
    let faceW: CGFloat
    let faceH: CGFloat

    init?(points: [CGPoint], aspect: CGFloat, size: CGSize) {
        guard points.count >= 478 else { return nil }
        let ar = max(aspect, 1e-4)
        let proj = points.map { CGPoint(x: $0.x * ar, y: $0.y) }
        let xs = proj.map(\.x)
        let ys = proj.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return nil }
        let bw = max(maxX - minX, 1e-4)
        let bh = max(maxY - minY, 1e-4)
        let pad: CGFloat = 0.13
        let scale = min(size.width * (1 - 2 * pad) / bw,
                        size.height * (1 - 2 * pad) / bh)
        let drawW = bw * scale
        let drawH = bh * scale
        let ox = (size.width - drawW) / 2
        let oy = (size.height - drawH) / 2
        pts = proj.map { CGPoint(x: ox + ($0.x - minX) * scale,
                                 y: oy + ($0.y - minY) * scale) }
        faceW = drawW
        faceH = drawH
    }
}

// MARK: - Mesh ID resolver

// target.json 由来の「化粧領域 → mesh ID」は不変。グリッドのスクロール再描画
// ごとに JSON を読み直さないよう、一度解決した結果をキャッシュする。
private enum SavedLookMeshLibrary {
    nonisolated(unsafe) private static var idCache: [String: [Int]] = [:]
    // 二重 Optional: 外側 nil = 未解決、内側 nil = 解決済みだが eyeliner データなし。
    nonisolated(unsafe) private static var eyelinerCache: EyeApplier.EyelinerData?? = nil
    private static let lock = NSLock()

    static func highlightIDs(_ names: Set<String>) -> [Int] {
        cached("h", names) { MakeupCompositionBuilder.meshIDs(.highlight, names: names) }
    }

    static func shadowIDs(_ names: Set<String>) -> [Int] {
        cached("s", names) { MakeupCompositionBuilder.meshIDs(.shadow, names: names) }
    }

    static func eyeshadowIDs(_ names: Set<String>) -> [Int] {
        cached("es", names) { MakeupCompositionBuilder.eyeMeshIDs(kind: .eyeshadow, names: names) }
    }

    static func tearbagIDs(_ names: Set<String>) -> [Int] {
        cached("tb", names) { MakeupCompositionBuilder.eyeMeshIDs(kind: .tearbag, names: names) }
    }

    static func eyebrowFullIDs() -> [Int] {
        cached("brow", []) {
            MeshAreaLibrary.lookup(category: .eyebrow, name: "eyebrow_full")?.meshIDs ?? []
        }
    }

    static func eyeliner() -> EyeApplier.EyelinerData? {
        lock.lock()
        defer { lock.unlock() }
        if let cached = eyelinerCache { return cached }
        let value = EyeApplier.loadFromTargetJSON().eyeliner
        eyelinerCache = .some(value)
        return value
    }

    private static func cached(_ prefix: String, _ names: Set<String>,
                               _ build: () -> [Int]) -> [Int] {
        let key = prefix + "|" + names.sorted().joined(separator: ",")
        lock.lock()
        defer { lock.unlock() }
        if let hit = idCache[key] { return hit }
        let value = build()
        idCache[key] = value
        return value
    }
}
