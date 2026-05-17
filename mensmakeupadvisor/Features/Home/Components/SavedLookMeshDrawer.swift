import SwiftUI

// SavedLookMeshThumbnail から描画ロジックだけを切り出した struct ヘルパ。
// 値型 GraphicsContext を持ち回す都合上、struct でメソッドを束ねる。
struct SavedLookMeshDrawer {
    var context: GraphicsContext
    let size: CGSize
    let look: SavedLook

    private let highlightColor = Color.ivory.opacity(0.78)
    private let shadowColor    = Color(red: 0.55, green: 0.35, blue: 0.20).opacity(0.85)
    private let eyeColor       = Color(red: 0.78, green: 0.55, blue: 0.35).opacity(0.95)
    private let linerColor     = Color.ivory.opacity(0.95)
    private let browColor      = Color(red: 0.35, green: 0.22, blue: 0.12).opacity(0.95)
    private let faint          = Color.ivory.opacity(0.18)

    func draw() {
        drawBackground()
        drawFaceOutline()
        drawHighlightZones(zones: look.highlightAreaSet)
        drawShadowZones(zones: look.shadowAreaSet)
        drawEyeZones(zones: look.eyeAreaSet)
        drawBrow(type: look.eyebrowTypeRaw)
        drawFeatureMarks()
    }

    private func drawBackground() {
        var ctx = context
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .color(Color(red: 0.10, green: 0.09, blue: 0.08)))
    }

    private func drawFaceOutline() {
        var ctx = context
        let cx = size.width / 2
        let cy = size.height / 2
        let w  = size.width * 0.62
        let h  = size.height * 0.78
        let rect = CGRect(x: cx - w / 2, y: cy - h / 2 + size.height * 0.02,
                          width: w, height: h)
        ctx.stroke(Path(ellipseIn: rect),
                   with: .color(Color.ivory.opacity(0.22)), lineWidth: 0.7)
    }

    // MARK: - Highlight

    private func drawHighlightZones(zones: Set<String>) {
        var ctx = context
        let cx = size.width / 2
        let H = size.height
        let W = size.width

        if zones.containsAny(of: ["base_t-zone", "marugao_t-zone", "omonaga_t-zone"]) {
            var path = Path()
            path.addEllipse(in: CGRect(x: cx - W * 0.16, y: H * 0.18,
                                        width: W * 0.32, height: H * 0.06))
            path.addEllipse(in: CGRect(x: cx - W * 0.025, y: H * 0.32,
                                        width: W * 0.05, height: H * 0.22))
            ctx.fill(path, with: .color(highlightColor))
        }
        if zones.containsAny(of: ["base_c-zone", "marugao_c-zone", "omonaga_c-zone"]) {
            for sign in [-1.0, 1.0] {
                let x = cx + CGFloat(sign) * W * 0.22
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - W * 0.06, y: H * 0.40,
                                            width: W * 0.12, height: H * 0.06)),
                    with: .color(highlightColor)
                )
            }
        }
        if zones.contains("base_under-eye") {
            for sign in [-1.0, 1.0] {
                let x = cx + CGFloat(sign) * W * 0.15
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - W * 0.05, y: H * 0.37,
                                            width: W * 0.10, height: H * 0.025)),
                    with: .color(highlightColor)
                )
            }
        }
        if zones.contains("base_megasira") {
            for sign in [-1.0, 1.0] {
                let x = cx + CGFloat(sign) * W * 0.07
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - W * 0.018, y: H * 0.36,
                                            width: W * 0.036, height: H * 0.025)),
                    with: .color(highlightColor)
                )
            }
        }
        if zones.contains("base_zintyuu") {
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - W * 0.018, y: H * 0.56,
                                        width: W * 0.036, height: H * 0.04)),
                with: .color(highlightColor)
            )
        }
        if zones.contains("marugao_ago") {
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - W * 0.06, y: H * 0.78,
                                        width: W * 0.12, height: H * 0.04)),
                with: .color(highlightColor)
            )
        }
    }

    // MARK: - Shadow

    private func drawShadowZones(zones: Set<String>) {
        var ctx = context
        let cx = size.width / 2
        let H = size.height
        let W = size.width
        if zones.contains("marugao-side") {
            for sign in [-1.0, 1.0] {
                let x = cx + CGFloat(sign) * W * 0.28
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - W * 0.05, y: H * 0.40,
                                            width: W * 0.10, height: H * 0.30)),
                    with: .color(shadowColor)
                )
            }
        }
        if zones.contains("omonaga-upper") {
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - W * 0.20, y: H * 0.13,
                                        width: W * 0.40, height: H * 0.05)),
                with: .color(shadowColor)
            )
        }
        if zones.contains("omonaga-lower") {
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - W * 0.13, y: H * 0.80,
                                        width: W * 0.26, height: H * 0.05)),
                with: .color(shadowColor)
            )
        }
    }

    // MARK: - Eye

    private func drawEyeZones(zones: Set<String>) {
        var ctx = context
        let cx = size.width / 2
        let H = size.height
        let W = size.width
        let eyeXs: [CGFloat] = [cx - W * 0.14, cx + W * 0.14]

        if zones.contains("eyeshadow_base") {
            for x in eyeXs {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - W * 0.08, y: H * 0.34,
                                            width: W * 0.16, height: H * 0.04)),
                    with: .color(eyeColor.opacity(0.55))
                )
            }
        }
        if zones.contains("eyeshadow_crease") {
            for x in eyeXs {
                var p = Path()
                p.move(to: CGPoint(x: x - W * 0.07, y: H * 0.345))
                p.addQuadCurve(to: CGPoint(x: x + W * 0.07, y: H * 0.345),
                                control: CGPoint(x: x, y: H * 0.32))
                ctx.stroke(p, with: .color(eyeColor), lineWidth: 1.5)
            }
        }
        if zones.contains("tear_bag") {
            for x in eyeXs {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - W * 0.05, y: H * 0.39,
                                            width: W * 0.10, height: H * 0.018)),
                    with: .color(highlightColor)
                )
            }
        }
        if zones.contains("lower_outer") {
            for (i, x) in eyeXs.enumerated() {
                let sign: CGFloat = i == 0 ? -1 : 1
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x + sign * W * 0.03 - W * 0.025,
                                            y: H * 0.395,
                                            width: W * 0.05, height: H * 0.018)),
                    with: .color(eyeColor)
                )
            }
        }
        if zones.contains("eyeliner") {
            for x in eyeXs {
                var p = Path()
                p.move(to: CGPoint(x: x - W * 0.075, y: H * 0.365))
                p.addLine(to: CGPoint(x: x + W * 0.075, y: H * 0.365))
                ctx.stroke(p, with: .color(linerColor), lineWidth: 1.2)
            }
        }
    }

    // MARK: - Brow

    private func drawBrow(type: String?) {
        guard let type, !type.isEmpty else { return }
        var ctx = context
        let cx = size.width / 2
        let H = size.height
        let W = size.width

        for sign in [-1.0, 1.0] {
            let x = cx + CGFloat(sign) * W * 0.14
            var path = Path()
            let leftX  = x - W * 0.08
            let rightX = x + W * 0.08
            let y = H * 0.30
            switch type {
            case "natural":
                path.move(to: CGPoint(x: leftX, y: y + H * 0.005))
                path.addQuadCurve(to: CGPoint(x: rightX, y: y),
                                  control: CGPoint(x: x, y: y - H * 0.02))
            case "straight":
                path.move(to: CGPoint(x: leftX, y: y))
                path.addLine(to: CGPoint(x: rightX, y: y))
            case "arch":
                path.move(to: CGPoint(x: leftX, y: y + H * 0.01))
                path.addQuadCurve(to: CGPoint(x: rightX, y: y),
                                  control: CGPoint(x: x, y: y - H * 0.035))
            case "parallel":
                path.move(to: CGPoint(x: leftX, y: y))
                path.addLine(to: CGPoint(x: rightX, y: y - H * 0.005))
            case "corner":
                path.move(to: CGPoint(x: leftX, y: y + H * 0.012))
                path.addLine(to: CGPoint(x: x, y: y - H * 0.015))
                path.addLine(to: CGPoint(x: rightX, y: y))
            default:
                continue
            }
            ctx.stroke(path, with: .color(browColor), lineWidth: 2.2)
        }
    }

    // 目・鼻・口の輪郭を薄く出して『顔のどこか』を分かりやすく
    private func drawFeatureMarks() {
        var ctx = context
        let cx = size.width / 2
        let H = size.height
        let W = size.width
        for sign in [-1.0, 1.0] {
            let x = cx + CGFloat(sign) * W * 0.14
            ctx.stroke(
                Path(ellipseIn: CGRect(x: x - W * 0.05, y: H * 0.355,
                                        width: W * 0.10, height: H * 0.025)),
                with: .color(faint), lineWidth: 0.6
            )
        }
        ctx.stroke(
            Path(ellipseIn: CGRect(x: cx - W * 0.025, y: H * 0.52,
                                    width: W * 0.05, height: H * 0.03)),
            with: .color(faint), lineWidth: 0.5
        )
        var mouth = Path()
        mouth.move(to: CGPoint(x: cx - W * 0.08, y: H * 0.65))
        mouth.addQuadCurve(to: CGPoint(x: cx + W * 0.08, y: H * 0.65),
                            control: CGPoint(x: cx, y: H * 0.66))
        ctx.stroke(mouth, with: .color(faint), lineWidth: 0.7)
    }
}

private extension Set where Element == String {
    func containsAny(of names: [String]) -> Bool {
        for n in names where contains(n) { return true }
        return false
    }
}
