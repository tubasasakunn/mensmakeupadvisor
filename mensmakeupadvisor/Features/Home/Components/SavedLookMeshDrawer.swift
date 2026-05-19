import SwiftUI

// SavedLook の化粧を、直近の顔診断で取得した facemesh の上に重ねて描く。
// 顔写真は使わず、メッシュのワイヤーフレームを下地に、ハイライト/シェード/
// アイ/眉を実ランドマーク基準の位置へ色付きで重ねる。ファンデーション
// (素肌ベース) は描かない。
struct SavedLookMeshDrawer {
    var context: GraphicsContext
    let size: CGSize
    let look: SavedLook
    // 478 点 facemesh (撮影画像に対する 0-1 正規化座標)。nil ならメッシュ未取得。
    let mesh: [CGPoint]?

    private let meshColor      = Color.ivory.opacity(0.16)
    private let highlightColor = Color(red: 1.0, green: 0.95, blue: 0.84)
    private let shadowColor    = Color(red: 0.40, green: 0.25, blue: 0.15)
    private let eyeColor       = Color(red: 0.76, green: 0.46, blue: 0.30)
    private let linerColor     = Color(red: 0.09, green: 0.07, blue: 0.06)
    private let browColor      = Color(red: 0.30, green: 0.20, blue: 0.12)

    func draw() {
        drawBackground()
        guard let layout = MeshLayout(mesh: mesh, size: size) else {
            drawPlaceholder()
            return
        }
        drawMesh(layout)
        // 乗算系 (シェード) を下、発光系 (ハイライト) を上に重ねる。
        drawShadowLayer(layout)
        drawHighlightLayer(layout)
        drawEyeLayer(layout)
        drawBrowLayer(layout)
    }

    // MARK: - Background / Placeholder

    private func drawBackground() {
        var ctx = context
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .color(Color(red: 0.10, green: 0.09, blue: 0.08)))
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
            ctx.stroke(p, with: .color(Color.ivory.opacity(0.10)), lineWidth: 0.5)
        }
        for r in 0...rows {
            var p = Path()
            let y = CGFloat(r) * size.height / CGFloat(rows)
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: size.width, y: y))
            ctx.stroke(p, with: .color(Color.ivory.opacity(0.10)), lineWidth: 0.5)
        }
    }

    // MARK: - Mesh wireframe

    private func drawMesh(_ layout: MeshLayout) {
        var ctx = context
        let edges = FaceMeshResources.tesselationConnections()
        if edges.isEmpty {
            // テッセレーション未ロード時は点群だけ描く。
            for p in layout.pts {
                let r: CGFloat = 0.5
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                         with: .color(meshColor))
            }
            return
        }
        var path = Path()
        for (a, b) in edges where layout.pts.indices.contains(a) && layout.pts.indices.contains(b) {
            path.move(to: layout.pts[a])
            path.addLine(to: layout.pts[b])
        }
        ctx.stroke(path, with: .color(meshColor), lineWidth: 0.3)
    }

    // MARK: - Highlight

    private func drawHighlightLayer(_ layout: MeshLayout) {
        let zones = look.highlightAreaSet
        guard !zones.isEmpty else { return }
        var ctx = context
        let color = highlightColor.opacity(intensityAlpha(look.highlight, base: 0.32, span: 0.40))
        let fw = layout.faceW
        let fh = layout.faceH

        if zones.containsAny(of: ["base_t-zone", "marugao_t-zone", "omonaga_t-zone"]) {
            // 額の中央 + 鼻筋
            let foreheadC = layout.lerp(layout.p(.foreheadTop), layout.p(.glabella), 0.48)
            fillEllipse(&ctx, center: foreheadC, w: fw * 0.34, h: fh * 0.10, color: color)
            let noseC = layout.mid(.glabella, .noseTip)
            fillEllipse(&ctx, center: noseC, w: fw * 0.08,
                        h: layout.dist(.glabella, .noseTip) * 1.05, color: color)
        }
        if zones.containsAny(of: ["base_c-zone", "marugao_c-zone", "omonaga_c-zone"]) {
            for eye in layout.eyes {
                let cheek = CGPoint(x: eye.center.x, y: eye.bot.y + fh * 0.07)
                fillEllipse(&ctx, center: cheek, w: fw * 0.16, h: fh * 0.07, color: color)
            }
        }
        if zones.contains("base_under-eye") {
            for eye in layout.eyes {
                let c = CGPoint(x: eye.center.x, y: eye.bot.y + fh * 0.022)
                fillEllipse(&ctx, center: c, w: eye.width * 1.1, h: fh * 0.022, color: color)
            }
        }
        if zones.contains("base_megasira") {
            fillEllipse(&ctx, center: layout.p(.eyeInnerR), w: fw * 0.045, h: fw * 0.035, color: color)
            fillEllipse(&ctx, center: layout.p(.eyeInnerL), w: fw * 0.045, h: fw * 0.035, color: color)
        }
        if zones.contains("base_zintyuu") {
            let c = layout.mid(.subnasal, .upperLipTop)
            fillEllipse(&ctx, center: c, w: fw * 0.05, h: fh * 0.045, color: color)
        }
        if zones.contains("marugao_ago") {
            let c = CGPoint(x: layout.p(.chinBottom).x, y: layout.p(.chinBottom).y - fh * 0.035)
            fillEllipse(&ctx, center: c, w: fw * 0.15, h: fh * 0.05, color: color)
        }
    }

    // MARK: - Shadow

    private func drawShadowLayer(_ layout: MeshLayout) {
        let zones = look.shadowAreaSet
        guard !zones.isEmpty else { return }
        var ctx = context
        let color = shadowColor.opacity(intensityAlpha(look.shadow, base: 0.40, span: 0.40))
        let fw = layout.faceW
        let fh = layout.faceH

        if zones.contains("marugao-side") {
            for (cheek, gonion) in [(layout.p(.cheekboneR), layout.p(.gonionR)),
                                    (layout.p(.cheekboneL), layout.p(.gonionL))] {
                let c = CGPoint(x: (cheek.x + gonion.x) / 2, y: (cheek.y + gonion.y) / 2)
                fillEllipse(&ctx, center: c, w: fw * 0.11, h: fh * 0.34, color: color)
            }
        }
        if zones.contains("omonaga-upper") {
            let c = layout.lerp(layout.p(.foreheadTop), layout.p(.glabella), 0.16)
            fillEllipse(&ctx, center: c, w: fw * 0.44, h: fh * 0.05, color: color)
        }
        if zones.contains("omonaga-lower") {
            let chin = layout.p(.chinBottom)
            fillEllipse(&ctx, center: CGPoint(x: chin.x, y: chin.y - fh * 0.012),
                        w: fw * 0.26, h: fh * 0.055, color: color)
        }
    }

    // MARK: - Eye

    private func drawEyeLayer(_ layout: MeshLayout) {
        let zones = look.eyeAreaSet
        guard !zones.isEmpty else { return }
        var ctx = context
        let a = intensityAlpha(look.eye, base: 0.40, span: 0.45)
        let shadowC = eyeColor.opacity(a)
        let creaseC = eyeColor.opacity(min(1, a + 0.15))
        let bagC = highlightColor.opacity(0.55)
        let liner = linerColor.opacity(min(1, a + 0.35))

        for eye in layout.eyes {
            if zones.contains("eyeshadow_base") {
                let c = CGPoint(x: eye.center.x, y: eye.center.y - eye.height * 0.35)
                fillEllipse(&ctx, center: c, w: eye.width * 1.25, h: eye.width * 0.46, color: shadowC)
            }
            if zones.contains("eyeshadow_crease") {
                var p = Path()
                p.move(to: CGPoint(x: eye.inner.x, y: eye.inner.y - eye.height * 0.2))
                p.addQuadCurve(
                    to: CGPoint(x: eye.outer.x, y: eye.outer.y - eye.height * 0.2),
                    control: CGPoint(x: eye.center.x, y: eye.top.y - eye.height * 1.1)
                )
                ctx.stroke(p, with: .color(creaseC), lineWidth: max(0.8, eye.width * 0.10))
            }
            if zones.contains("tear_bag") {
                let c = CGPoint(x: eye.center.x, y: eye.bot.y + eye.height * 0.35)
                fillEllipse(&ctx, center: c, w: eye.width * 0.72, h: eye.height * 0.42, color: bagC)
            }
            if zones.contains("lower_outer") {
                let c = CGPoint(x: eye.outer.x - (eye.outer.x - eye.center.x) * 0.35,
                                y: eye.bot.y + eye.height * 0.25)
                fillEllipse(&ctx, center: c, w: eye.width * 0.34, h: eye.height * 0.34, color: shadowC)
            }
            if zones.contains("eyeliner") {
                var p = Path()
                p.move(to: eye.inner)
                p.addQuadCurve(to: eye.outer,
                               control: CGPoint(x: eye.center.x, y: eye.top.y - eye.height * 0.1))
                ctx.stroke(p, with: .color(liner), lineWidth: max(0.9, eye.width * 0.09))
            }
        }
    }

    // MARK: - Brow

    private func drawBrowLayer(_ layout: MeshLayout) {
        guard let type = look.eyebrowTypeRaw, !type.isEmpty else { return }
        var ctx = context
        let color = browColor.opacity(intensityAlpha(look.eyebrow, base: 0.55, span: 0.40))
        let width = max(1.2, layout.faceW * 0.024)

        for (head, peak, tail) in [
            (layout.p(.browHeadR), layout.p(.browPeakR), layout.p(.browTailR)),
            (layout.p(.browHeadL), layout.p(.browPeakL), layout.p(.browTailL)),
        ] {
            var p = Path()
            p.move(to: head)
            // type で山の高さを微調整する。straight はほぼ直線、arch は山を上げる。
            let liftFactor: CGFloat = switch type {
            case "straight", "parallel": 0.3
            case "arch":                 1.6
            case "corner":               1.25
            default:                     1.0
            }
            let lift = (peak.y - (head.y + tail.y) / 2) * liftFactor
            let control = CGPoint(x: peak.x, y: (head.y + tail.y) / 2 + lift)
            p.addQuadCurve(to: tail, control: control)
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
    }

    // MARK: - Helpers

    private func fillEllipse(_ ctx: inout GraphicsContext,
                             center: CGPoint, w: CGFloat, h: CGFloat, color: Color) {
        ctx.fill(
            Path(ellipseIn: CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)),
            with: .color(color)
        )
    }

    // 化粧の強度 (0-100) を不透明度に写像する。0 でも薄く見えるよう下限を設ける。
    private func intensityAlpha(_ intensity: Double, base: Double, span: Double) -> Double {
        let t = min(1, max(0, intensity / 100))
        return min(1, base + span * t)
    }
}

// MARK: - MeshLayout

// 正規化メッシュをサムネイル座標へ写像し、名前付きアンカーを引けるようにする。
private struct MeshLayout {
    let pts: [CGPoint]
    let faceW: CGFloat
    let faceH: CGFloat
    let eyes: [EyeAnchor]

    struct EyeAnchor {
        let center: CGPoint
        let inner: CGPoint
        let outer: CGPoint
        let top: CGPoint
        let bot: CGPoint
        let width: CGFloat
        let height: CGFloat
    }

    init?(mesh: [CGPoint]?, size: CGSize) {
        guard let mesh, mesh.count >= 468 else { return nil }
        let xs = mesh.map(\.x)
        let ys = mesh.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return nil }
        let bw = max(maxX - minX, 1e-4)
        let bh = max(maxY - minY, 1e-4)
        let pad: CGFloat = 0.13
        let availW = size.width * (1 - 2 * pad)
        let availH = size.height * (1 - 2 * pad)
        let scale = min(availW / bw, availH / bh)
        let drawW = bw * scale
        let drawH = bh * scale
        let ox = (size.width - drawW) / 2
        let oy = (size.height - drawH) / 2
        let transformed = mesh.map { p in
            CGPoint(x: ox + (p.x - minX) * scale, y: oy + (p.y - minY) * scale)
        }
        pts = transformed
        faceW = drawW
        faceH = drawH

        func at(_ id: Int) -> CGPoint { transformed.indices.contains(id) ? transformed[id] : .zero }
        func eye(outer: Int, inner: Int, top: Int, bot: Int) -> EyeAnchor {
            let po = at(outer), pi = at(inner), pt = at(top), pb = at(bot)
            let center = CGPoint(x: (po.x + pi.x) / 2, y: (pt.y + pb.y) / 2)
            return EyeAnchor(
                center: center, inner: pi, outer: po, top: pt, bot: pb,
                width: max(1, MeshLayout.span(po, pi)),
                height: max(1, MeshLayout.span(pt, pb))
            )
        }
        eyes = [
            eye(outer: FaceLandmarkID.eyeOuterR, inner: FaceLandmarkID.eyeInnerR,
                top: FaceLandmarkID.eyeTopR, bot: FaceLandmarkID.eyeBotR),
            eye(outer: FaceLandmarkID.eyeOuterL, inner: FaceLandmarkID.eyeInnerL,
                top: FaceLandmarkID.eyeTopL, bot: FaceLandmarkID.eyeBotL),
        ]
    }

    enum Anchor {
        case foreheadTop, glabella, noseTip, subnasal, upperLipTop, chinBottom
        case eyeInnerR, eyeInnerL
        case cheekboneR, cheekboneL, gonionR, gonionL
        case browHeadR, browPeakR, browTailR, browHeadL, browPeakL, browTailL

        var id: Int {
            switch self {
            case .foreheadTop:  FaceLandmarkID.foreheadTop
            case .glabella:     FaceLandmarkID.glabella
            case .noseTip:      FaceLandmarkID.noseTip
            case .subnasal:     FaceLandmarkID.subnasal
            case .upperLipTop:  FaceLandmarkID.upperLipTop
            case .chinBottom:   FaceLandmarkID.chinBottom
            case .eyeInnerR:    FaceLandmarkID.eyeInnerR
            case .eyeInnerL:    FaceLandmarkID.eyeInnerL
            case .cheekboneR:   FaceLandmarkID.cheekboneR
            case .cheekboneL:   FaceLandmarkID.cheekboneL
            case .gonionR:      FaceLandmarkID.gonionR
            case .gonionL:      FaceLandmarkID.gonionL
            case .browHeadR:    FaceLandmarkID.browHeadR
            case .browPeakR:    FaceLandmarkID.browPeakR
            case .browTailR:    FaceLandmarkID.browTailR
            case .browHeadL:    FaceLandmarkID.browHeadL
            case .browPeakL:    FaceLandmarkID.browPeakL
            case .browTailL:    FaceLandmarkID.browTailL
            }
        }
    }

    func p(_ a: Anchor) -> CGPoint { pts.indices.contains(a.id) ? pts[a.id] : .zero }

    func mid(_ a: Anchor, _ b: Anchor) -> CGPoint {
        let pa = p(a), pb = p(b)
        return CGPoint(x: (pa.x + pb.x) / 2, y: (pa.y + pb.y) / 2)
    }

    func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    func dist(_ a: Anchor, _ b: Anchor) -> CGFloat {
        MeshLayout.span(p(a), p(b))
    }

    static func span(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

private extension Set where Element == String {
    func containsAny(of names: [String]) -> Bool {
        for n in names where contains(n) { return true }
        return false
    }
}
