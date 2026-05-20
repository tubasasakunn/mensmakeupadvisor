import SwiftUI

// ScoreAnnotationView から描画ロジックだけを切り出した値型ヘルパ。
// GraphicsContext は値型で持ち回しが必要なため、struct で抱える形にする。
struct ScoreAnnotationDrawer {
    var context: GraphicsContext
    let size: CGSize
    let landmarks: [CGPoint]

    private let primary = Theme.Annotation.primary
    private let accent  = Theme.Annotation.accent
    private let sub     = Theme.Annotation.sub

    func point(_ id: Int) -> CGPoint {
        let p = landmarks[id]
        return CGPoint(x: p.x * size.width, y: p.y * size.height)
    }

    // MARK: - 骨格バランス
    func drawSkeletalBalance() {
        var ctx = context
        let templeR = point(FaceLandmarkID.templeR)
        let templeL = point(FaceLandmarkID.templeL)
        let foreheadY = point(FaceLandmarkID.foreheadTop).y
        let chinY     = point(FaceLandmarkID.chinBottom).y
        let cheekR = point(FaceLandmarkID.cheekboneR)
        let cheekL = point(FaceLandmarkID.cheekboneL)
        let jawR   = point(FaceLandmarkID.gonionR)
        let jawL   = point(FaceLandmarkID.gonionL)

        let rect = CGRect(
            x: min(templeR.x, cheekR.x, jawR.x),
            y: foreheadY,
            width: max(templeL.x, cheekL.x, jawL.x) - min(templeR.x, cheekR.x, jawR.x),
            height: chinY - foreheadY
        )
        ctx.stroke(Path(roundedRect: rect, cornerRadius: 2), with: .color(accent), lineWidth: 1.0)
        drawHorizontalRange(ctx: &ctx, a: cheekR, b: cheekL, color: primary, label: "頬骨幅")
        drawHorizontalRange(ctx: &ctx, a: jawR, b: jawL, color: sub, label: "顎幅")
        drawVerticalRange(ctx: &ctx,
                          top: CGPoint(x: rect.maxX + 8, y: foreheadY),
                          bottom: CGPoint(x: rect.maxX + 8, y: chinY),
                          color: primary, label: "顔高")
    }

    // MARK: - 三分割
    func drawVerticalThirds() {
        var ctx = context
        let foreheadY = point(FaceLandmarkID.foreheadTop).y
        let glabellaY = point(FaceLandmarkID.glabella).y
        let subnasalY = point(FaceLandmarkID.subnasal).y
        let chinY     = point(FaceLandmarkID.chinBottom).y

        for y in [foreheadY, glabellaY, subnasalY, chinY] {
            strokeHorizontalLine(ctx: &ctx, y: y, color: accent, width: 1.0)
        }
        let labels: [(CGFloat, String)] = [
            ((foreheadY + glabellaY) / 2, "① 額"),
            ((glabellaY + subnasalY) / 2, "② 中顔面"),
            ((subnasalY + chinY) / 2,     "③ 下顔面"),
        ]
        for (y, label) in labels {
            drawLabel(ctx: &ctx, text: label, at: CGPoint(x: size.width - 6, y: y),
                      align: .trailing, color: accent)
        }
    }

    // MARK: - 五分割
    func drawHorizontalFifths() {
        var ctx = context
        let foreheadY = point(FaceLandmarkID.foreheadTop).y
        let chinY     = point(FaceLandmarkID.chinBottom).y
        let xs: [(CGFloat, String?)] = [
            (point(FaceLandmarkID.templeR).x,   "①"),
            (point(FaceLandmarkID.eyeOuterR).x, "②"),
            (point(FaceLandmarkID.eyeInnerR).x, "③"),
            (point(FaceLandmarkID.eyeInnerL).x, "④"),
            (point(FaceLandmarkID.eyeOuterL).x, "⑤"),
            (point(FaceLandmarkID.templeL).x,   nil),
        ]
        for (x, _) in xs {
            var p = Path()
            p.move(to: CGPoint(x: x, y: foreheadY))
            p.addLine(to: CGPoint(x: x, y: chinY))
            ctx.stroke(p, with: .color(sub), lineWidth: 0.9)
        }
        for (left, right) in zip(xs.dropLast(), xs.dropFirst()) {
            guard let label = left.1 else { continue }
            let cx = (left.0 + right.0) / 2
            drawLabel(ctx: &ctx, text: label, at: CGPoint(x: cx, y: foreheadY - 8),
                      align: .center, color: sub)
        }
    }

    // MARK: - 目の比率
    func drawEyeRatio() {
        var ctx = context
        drawHorizontalRange(ctx: &ctx,
                            a: point(FaceLandmarkID.eyeOuterR),
                            b: point(FaceLandmarkID.eyeInnerR),
                            color: primary, label: "横")
        drawVerticalRange(ctx: &ctx,
                          top: point(FaceLandmarkID.eyeTopR),
                          bottom: point(FaceLandmarkID.eyeBotR),
                          color: accent, label: "縦")
        drawHorizontalRange(ctx: &ctx,
                            a: point(FaceLandmarkID.eyeInnerL),
                            b: point(FaceLandmarkID.eyeOuterL),
                            color: primary, label: "横")
        drawVerticalRange(ctx: &ctx,
                          top: point(FaceLandmarkID.eyeTopL),
                          bottom: point(FaceLandmarkID.eyeBotL),
                          color: accent, label: "縦")
    }

    // MARK: - 鼻のバランス
    func drawNoseBalance() {
        var ctx = context
        drawHorizontalRange(ctx: &ctx,
                            a: point(FaceLandmarkID.noseWingROut),
                            b: point(FaceLandmarkID.noseWingLOut),
                            color: primary, label: "鼻幅")
        drawHorizontalRange(ctx: &ctx,
                            a: point(FaceLandmarkID.eyeInnerR),
                            b: point(FaceLandmarkID.eyeInnerL),
                            color: sub, label: "目間")
        var p = Path()
        p.move(to: point(FaceLandmarkID.noseRoot))
        p.addLine(to: point(FaceLandmarkID.noseTip))
        ctx.stroke(p, with: .color(accent), lineWidth: 1.0)
    }

    // MARK: - 口の比率
    func drawMouthRatio() {
        var ctx = context
        drawHorizontalRange(ctx: &ctx,
                            a: point(FaceLandmarkID.mouthR),
                            b: point(FaceLandmarkID.mouthL),
                            color: primary, label: "口幅")
        drawVerticalRange(ctx: &ctx,
                          top: point(FaceLandmarkID.upperLipTop),
                          bottom: point(FaceLandmarkID.upperLipIn),
                          color: accent, label: "上唇")
        drawVerticalRange(ctx: &ctx,
                          top: point(FaceLandmarkID.lowerLipIn),
                          bottom: point(FaceLandmarkID.lowerLipBot),
                          color: sub, label: "下唇")
    }

    // MARK: - 左右対称性
    func drawSymmetry() {
        var ctx = context
        let topMid = point(FaceLandmarkID.foreheadTop)
        let bottomMid = point(FaceLandmarkID.chinBottom)
        let midX = (topMid.x + bottomMid.x) / 2

        var center = Path()
        center.move(to: CGPoint(x: midX, y: topMid.y))
        center.addLine(to: CGPoint(x: midX, y: bottomMid.y))
        ctx.stroke(center, with: .color(accent), lineWidth: 1.0)

        let pairs: [(Int, Int, String)] = [
            (FaceLandmarkID.eyeOuterR,  FaceLandmarkID.eyeOuterL,  "目尻"),
            (FaceLandmarkID.mouthR,     FaceLandmarkID.mouthL,     "口角"),
            (FaceLandmarkID.cheekboneR, FaceLandmarkID.cheekboneL, "頬骨"),
        ]
        for (r, l, label) in pairs {
            let pr = point(r)
            let pl = point(l)
            for p in [pr, pl] {
                let rect = CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)
                ctx.fill(Path(ellipseIn: rect), with: .color(primary))
            }
            var line = Path()
            line.move(to: pr)
            line.addLine(to: pl)
            ctx.stroke(line, with: .color(primary.opacity(0.6)),
                       style: StrokeStyle(lineWidth: 0.7, dash: [3, 3]))
            drawLabel(ctx: &ctx, text: label,
                      at: CGPoint(x: (pr.x + pl.x) / 2, y: (pr.y + pl.y) / 2 - 6),
                      align: .center, color: primary)
        }
    }

    // MARK: - 描画プリミティブ

    private func strokeHorizontalLine(ctx: inout GraphicsContext, y: CGFloat, color: Color, width: CGFloat) {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: y))
        p.addLine(to: CGPoint(x: size.width, y: y))
        ctx.stroke(p, with: .color(color), lineWidth: width)
    }

    private func drawHorizontalRange(ctx: inout GraphicsContext,
                                     a: CGPoint, b: CGPoint, color: Color, label: String) {
        let y = (a.y + b.y) / 2
        var line = Path()
        line.move(to: CGPoint(x: a.x, y: y))
        line.addLine(to: CGPoint(x: b.x, y: y))
        ctx.stroke(line, with: .color(color), lineWidth: 1.2)
        for x in [a.x, b.x] {
            var bar = Path()
            bar.move(to: CGPoint(x: x, y: y - 4))
            bar.addLine(to: CGPoint(x: x, y: y + 4))
            ctx.stroke(bar, with: .color(color), lineWidth: 1.0)
        }
        drawLabel(ctx: &ctx, text: label,
                  at: CGPoint(x: (a.x + b.x) / 2, y: y - 7),
                  align: .center, color: color)
    }

    private func drawVerticalRange(ctx: inout GraphicsContext,
                                   top: CGPoint, bottom: CGPoint, color: Color, label: String) {
        let x = (top.x + bottom.x) / 2
        var line = Path()
        line.move(to: CGPoint(x: x, y: top.y))
        line.addLine(to: CGPoint(x: x, y: bottom.y))
        ctx.stroke(line, with: .color(color), lineWidth: 1.2)
        for y in [top.y, bottom.y] {
            var bar = Path()
            bar.move(to: CGPoint(x: x - 4, y: y))
            bar.addLine(to: CGPoint(x: x + 4, y: y))
            ctx.stroke(bar, with: .color(color), lineWidth: 1.0)
        }
        drawLabel(ctx: &ctx, text: label,
                  at: CGPoint(x: x + 10, y: (top.y + bottom.y) / 2),
                  align: .leading, color: color)
    }

    private enum LabelAlign { case leading, center, trailing }

    private func drawLabel(ctx: inout GraphicsContext, text: String,
                           at p: CGPoint, align: LabelAlign, color: Color) {
        let t = Text(text)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(color)
        let resolved = ctx.resolve(t)
        let bounds = resolved.measure(in: CGSize(width: 200, height: 40))
        let centerX: CGFloat = switch align {
        case .leading:  p.x + bounds.width / 2
        case .center:   p.x
        case .trailing: p.x - bounds.width / 2
        }
        ctx.draw(resolved, at: CGPoint(x: centerX, y: p.y))
    }
}
