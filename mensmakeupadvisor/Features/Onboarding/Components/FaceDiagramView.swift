import SwiftUI

// 顔の線画ダイアグラム。region 引数で強調部分を色分けする。
struct FaceDiagramView: View {
    let region: String  // "base", "highlight", "shadow", "eyes", "brows"
    var caption: String = ""

    var body: some View {
        VStack(spacing: 8) {
            Canvas { ctx, size in
                let w = size.width
                let h = size.height

                // 座標系: 顔全体を w×h に収める
                let cx = w / 2
                let faceTop = h * 0.04
                let faceBottom = h * 0.88
                let faceH = faceBottom - faceTop
                let faceW = w * 0.60
                let faceLeft = cx - faceW / 2
                let faceRight = cx + faceW / 2

                // MARK: Region overlays (before line art)
                switch region {
                case "base":
                    drawBaseOverlay(ctx: ctx, cx: cx, faceLeft: faceLeft, faceRight: faceRight, faceTop: faceTop, faceH: faceH, w: w)
                case "highlight":
                    drawHighlightOverlay(ctx: ctx, cx: cx, faceTop: faceTop, faceH: faceH, faceW: faceW)
                case "shadow":
                    drawShadowOverlay(ctx: ctx, cx: cx, faceLeft: faceLeft, faceRight: faceRight, faceTop: faceTop, faceH: faceH, faceW: faceW)
                case "eyes":
                    drawEyesOverlay(ctx: ctx, cx: cx, faceTop: faceTop, faceH: faceH)
                case "brows":
                    drawBrowsOverlay(ctx: ctx, cx: cx, faceTop: faceTop, faceH: faceH)
                default:
                    break
                }

                // MARK: Face outline
                let faceRect = CGRect(
                    x: faceLeft,
                    y: faceTop,
                    width: faceW,
                    height: faceH
                )
                var facePath = Path(ellipseIn: faceRect)
                ctx.stroke(
                    facePath,
                    with: .color(Color.ivory.opacity(0.55)),
                    lineWidth: 1.2
                )

                // MARK: Chin narrowing hint (jaw)
                let jawTop = faceTop + faceH * 0.65
                var jawPath = Path()
                jawPath.move(to: CGPoint(x: faceLeft + faceW * 0.08, y: jawTop))
                jawPath.addQuadCurve(
                    to: CGPoint(x: cx, y: faceBottom),
                    control: CGPoint(x: faceLeft + faceW * 0.04, y: faceBottom - faceH * 0.06)
                )
                jawPath.move(to: CGPoint(x: faceRight - faceW * 0.08, y: jawTop))
                jawPath.addQuadCurve(
                    to: CGPoint(x: cx, y: faceBottom),
                    control: CGPoint(x: faceRight - faceW * 0.04, y: faceBottom - faceH * 0.06)
                )
                ctx.stroke(jawPath, with: .color(Color.ivory.opacity(0.4)), lineWidth: 0.8)

                // MARK: Eyebrows
                let browY = faceTop + faceH * 0.26
                let browSpread = faceW * 0.24
                let browHalf = faceW * 0.14
                var browsPath = Path()
                // Left brow
                browsPath.move(to: CGPoint(x: cx - browSpread - browHalf, y: browY + 3))
                browsPath.addQuadCurve(
                    to: CGPoint(x: cx - browSpread + browHalf, y: browY - 3),
                    control: CGPoint(x: cx - browSpread, y: browY - 6)
                )
                // Right brow
                browsPath.move(to: CGPoint(x: cx + browSpread - browHalf, y: browY - 3))
                browsPath.addQuadCurve(
                    to: CGPoint(x: cx + browSpread + browHalf, y: browY + 3),
                    control: CGPoint(x: cx + browSpread, y: browY - 6)
                )

                let browColor: Color = region == "brows" ? Color.brandPrimary : Color.ivory.opacity(0.6)
                let browWidth: CGFloat = region == "brows" ? 3.0 : 1.4
                ctx.stroke(browsPath, with: .color(browColor), lineWidth: browWidth)

                // MARK: Eyes
                let eyeY = faceTop + faceH * 0.34
                let eyeSpread = faceW * 0.22
                let eyeRx: CGFloat = faceW * 0.10
                let eyeRy: CGFloat = faceH * 0.048

                let eyeColor: Color = region == "eyes" ? Color.brandPrimary.opacity(0.9) : Color.ivory.opacity(0.55)

                let leftEyeRect = CGRect(x: cx - eyeSpread - eyeRx, y: eyeY - eyeRy, width: eyeRx * 2, height: eyeRy * 2)
                let rightEyeRect = CGRect(x: cx + eyeSpread - eyeRx, y: eyeY - eyeRy, width: eyeRx * 2, height: eyeRy * 2)
                ctx.stroke(Path(ellipseIn: leftEyeRect), with: .color(eyeColor), lineWidth: region == "eyes" ? 1.8 : 1.0)
                ctx.stroke(Path(ellipseIn: rightEyeRect), with: .color(eyeColor), lineWidth: region == "eyes" ? 1.8 : 1.0)

                // MARK: Nose
                let noseTopY = faceTop + faceH * 0.42
                let noseTipY = faceTop + faceH * 0.60
                let noseW = faceW * 0.12
                var nosePath = Path()
                nosePath.move(to: CGPoint(x: cx, y: noseTopY))
                nosePath.addLine(to: CGPoint(x: cx, y: noseTipY))
                nosePath.addQuadCurve(
                    to: CGPoint(x: cx + noseW, y: noseTipY - 2),
                    control: CGPoint(x: cx + noseW * 0.5, y: noseTipY + 5)
                )
                nosePath.move(to: CGPoint(x: cx, y: noseTipY))
                nosePath.addQuadCurve(
                    to: CGPoint(x: cx - noseW, y: noseTipY - 2),
                    control: CGPoint(x: cx - noseW * 0.5, y: noseTipY + 5)
                )
                ctx.stroke(nosePath, with: .color(Color.ivory.opacity(0.45)), lineWidth: 0.9)

                // MARK: Mouth
                let mouthY = faceTop + faceH * 0.71
                let mouthW = faceW * 0.22
                var mouthPath = Path()
                mouthPath.move(to: CGPoint(x: cx - mouthW, y: mouthY))
                mouthPath.addQuadCurve(
                    to: CGPoint(x: cx + mouthW, y: mouthY),
                    control: CGPoint(x: cx, y: mouthY + 5)
                )
                ctx.stroke(mouthPath, with: .color(Color.ivory.opacity(0.4)), lineWidth: 0.9)

                // MARK: Center line
                var centerLine = Path()
                centerLine.move(to: CGPoint(x: cx, y: faceTop + faceH * 0.04))
                centerLine.addLine(to: CGPoint(x: cx, y: faceTop + faceH * 0.22))
                ctx.stroke(
                    centerLine,
                    with: .color(Color.ivory.opacity(0.12)),
                    style: StrokeStyle(lineWidth: 0.5, dash: [3, 4])
                )

                // MARK: FIG label (bottom right)
                if !caption.isEmpty {
                    let figText = Text(caption)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(Color.inkSecondary)
                    ctx.draw(figText, at: CGPoint(x: w - 4, y: h - 4), anchor: .bottomTrailing)
                }
            }
            .frame(width: 160, height: 190)
        }
    }

    // MARK: - Overlay drawing helpers

    private func drawBaseOverlay(
        ctx: GraphicsContext, cx: CGFloat,
        faceLeft: CGFloat, faceRight: CGFloat,
        faceTop: CGFloat, faceH: CGFloat, w: CGFloat
    ) {
        let faceRect = CGRect(x: faceLeft, y: faceTop, width: faceRight - faceLeft, height: faceH)
        ctx.fill(Path(ellipseIn: faceRect), with: .color(Color.ivory.opacity(0.06)))
    }

    private func drawHighlightOverlay(
        ctx: GraphicsContext, cx: CGFloat,
        faceTop: CGFloat, faceH: CGFloat, faceW: CGFloat
    ) {
        let hl = Color.ivory.opacity(0.28)
        // 鼻筋
        let noseRect = CGRect(x: cx - 4, y: faceTop + faceH * 0.38, width: 8, height: faceH * 0.24)
        ctx.fill(Path(ellipseIn: noseRect), with: .color(hl))
        // 額中央
        let foreRect = CGRect(x: cx - 14, y: faceTop + faceH * 0.08, width: 28, height: faceH * 0.14)
        ctx.fill(Path(ellipseIn: foreRect), with: .color(hl))
        // 左頬骨
        let lcRect = CGRect(x: cx - faceW * 0.34, y: faceTop + faceH * 0.37, width: 20, height: 12)
        ctx.fill(Path(ellipseIn: lcRect), with: .color(hl))
        // 右頬骨
        let rcRect = CGRect(x: cx + faceW * 0.34 - 20, y: faceTop + faceH * 0.37, width: 20, height: 12)
        ctx.fill(Path(ellipseIn: rcRect), with: .color(hl))
        // あご先
        let chinRect = CGRect(x: cx - 10, y: faceTop + faceH * 0.82, width: 20, height: 10)
        ctx.fill(Path(ellipseIn: chinRect), with: .color(hl))
    }

    private func drawShadowOverlay(
        ctx: GraphicsContext, cx: CGFloat,
        faceLeft: CGFloat, faceRight: CGFloat,
        faceTop: CGFloat, faceH: CGFloat, faceW: CGFloat
    ) {
        let sh = Color.brandPrimary.opacity(0.22)
        // 左こめかみ
        let ltRect = CGRect(x: faceLeft - 2, y: faceTop + faceH * 0.18, width: 22, height: 28)
        ctx.fill(Path(ellipseIn: ltRect), with: .color(sh))
        // 右こめかみ
        let rtRect = CGRect(x: faceRight - 20, y: faceTop + faceH * 0.18, width: 22, height: 28)
        ctx.fill(Path(ellipseIn: rtRect), with: .color(sh))
        // 左フェイスライン
        let lfRect = CGRect(x: faceLeft, y: faceTop + faceH * 0.55, width: 18, height: 40)
        ctx.fill(Path(ellipseIn: lfRect), with: .color(sh))
        // 右フェイスライン
        let rfRect = CGRect(x: faceRight - 18, y: faceTop + faceH * 0.55, width: 18, height: 40)
        ctx.fill(Path(ellipseIn: rfRect), with: .color(sh))
    }

    private func drawEyesOverlay(
        ctx: GraphicsContext, cx: CGFloat,
        faceTop: CGFloat, faceH: CGFloat
    ) {
        let eyeY = faceTop + faceH * 0.34
        let eyeSpread: CGFloat = 22
        let hl = Color.ivory.opacity(0.3)
        // 涙袋ハイライト（目の下）
        let ltRect = CGRect(x: cx - eyeSpread - 14, y: eyeY + 7, width: 28, height: 8)
        ctx.fill(Path(ellipseIn: ltRect), with: .color(hl))
        let rtRect = CGRect(x: cx + eyeSpread - 14, y: eyeY + 7, width: 28, height: 8)
        ctx.fill(Path(ellipseIn: rtRect), with: .color(hl))
    }

    private func drawBrowsOverlay(
        ctx: GraphicsContext, cx: CGFloat,
        faceTop: CGFloat, faceH: CGFloat
    ) {
        // brows は線アートで表現するため overlay は不要
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        ForEach(["base", "highlight", "shadow", "eyes", "brows"], id: \.self) { r in
            VStack {
                FaceDiagramView(region: r, caption: "FIG. \(r.uppercased())")
                Text(r).font(.caption).foregroundStyle(Color.inkSecondary)
            }
        }
    }
    .padding()
    .background(Color.appBackground)
}
