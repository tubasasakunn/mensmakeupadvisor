import SwiftUI

extension FaceDiagramView {
    func drawBaseOverlay(
        ctx: GraphicsContext, cx: CGFloat,
        faceLeft: CGFloat, faceRight: CGFloat,
        faceTop: CGFloat, faceH: CGFloat, w: CGFloat
    ) {
        let faceRect = CGRect(x: faceLeft, y: faceTop, width: faceRight - faceLeft, height: faceH)
        ctx.fill(Path(ellipseIn: faceRect), with: .color(Color.ivory.opacity(0.06)))
    }

    func drawHighlightOverlay(
        ctx: GraphicsContext, cx: CGFloat,
        faceTop: CGFloat, faceH: CGFloat, faceW: CGFloat
    ) {
        let hl = Color.ivory.opacity(0.28)
        let noseRect = CGRect(x: cx - 4, y: faceTop + faceH * 0.38, width: 8, height: faceH * 0.24)
        ctx.fill(Path(ellipseIn: noseRect), with: .color(hl))
        let foreRect = CGRect(x: cx - 14, y: faceTop + faceH * 0.08, width: 28, height: faceH * 0.14)
        ctx.fill(Path(ellipseIn: foreRect), with: .color(hl))
        let lcRect = CGRect(x: cx - faceW * 0.34, y: faceTop + faceH * 0.37, width: 20, height: 12)
        ctx.fill(Path(ellipseIn: lcRect), with: .color(hl))
        let rcRect = CGRect(x: cx + faceW * 0.34 - 20, y: faceTop + faceH * 0.37, width: 20, height: 12)
        ctx.fill(Path(ellipseIn: rcRect), with: .color(hl))
        let chinRect = CGRect(x: cx - 10, y: faceTop + faceH * 0.82, width: 20, height: 10)
        ctx.fill(Path(ellipseIn: chinRect), with: .color(hl))
    }

    func drawShadowOverlay(
        ctx: GraphicsContext, cx: CGFloat,
        faceLeft: CGFloat, faceRight: CGFloat,
        faceTop: CGFloat, faceH: CGFloat, faceW: CGFloat
    ) {
        let sh = Color.brandPrimary.opacity(0.22)
        let ltRect = CGRect(x: faceLeft - 2, y: faceTop + faceH * 0.18, width: 22, height: 28)
        ctx.fill(Path(ellipseIn: ltRect), with: .color(sh))
        let rtRect = CGRect(x: faceRight - 20, y: faceTop + faceH * 0.18, width: 22, height: 28)
        ctx.fill(Path(ellipseIn: rtRect), with: .color(sh))
        let lfRect = CGRect(x: faceLeft, y: faceTop + faceH * 0.55, width: 18, height: 40)
        ctx.fill(Path(ellipseIn: lfRect), with: .color(sh))
        let rfRect = CGRect(x: faceRight - 18, y: faceTop + faceH * 0.55, width: 18, height: 40)
        ctx.fill(Path(ellipseIn: rfRect), with: .color(sh))
    }

    func drawEyesOverlay(
        ctx: GraphicsContext, cx: CGFloat,
        faceTop: CGFloat, faceH: CGFloat
    ) {
        let eyeY = faceTop + faceH * 0.34
        let eyeSpread: CGFloat = 22
        let hl = Color.ivory.opacity(0.3)
        let ltRect = CGRect(x: cx - eyeSpread - 14, y: eyeY + 7, width: 28, height: 8)
        ctx.fill(Path(ellipseIn: ltRect), with: .color(hl))
        let rtRect = CGRect(x: cx + eyeSpread - 14, y: eyeY + 7, width: 28, height: 8)
        ctx.fill(Path(ellipseIn: rtRect), with: .color(hl))
    }

    func drawBrowsOverlay(
        ctx: GraphicsContext, cx: CGFloat,
        faceTop: CGFloat, faceH: CGFloat
    ) {
        // brows は線アートで表現するため overlay は不要
    }
}
