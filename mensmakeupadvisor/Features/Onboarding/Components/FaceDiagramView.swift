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

                let cx = w / 2
                let faceTop = h * 0.04
                let faceBottom = h * 0.88
                let faceH = faceBottom - faceTop
                let faceW = w * 0.60
                let faceLeft = cx - faceW / 2
                let faceRight = cx + faceW / 2

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

                let faceRect = CGRect(x: faceLeft, y: faceTop, width: faceW, height: faceH)
                let facePath = Path(ellipseIn: faceRect)
                ctx.stroke(facePath, with: .color(Color.ivory.opacity(0.55)), lineWidth: 1.2)

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

                let browY = faceTop + faceH * 0.26
                let browSpread = faceW * 0.24
                let browHalf = faceW * 0.14
                var browsPath = Path()
                browsPath.move(to: CGPoint(x: cx - browSpread - browHalf, y: browY + 3))
                browsPath.addQuadCurve(
                    to: CGPoint(x: cx - browSpread + browHalf, y: browY - 3),
                    control: CGPoint(x: cx - browSpread, y: browY - 6)
                )
                browsPath.move(to: CGPoint(x: cx + browSpread - browHalf, y: browY - 3))
                browsPath.addQuadCurve(
                    to: CGPoint(x: cx + browSpread + browHalf, y: browY + 3),
                    control: CGPoint(x: cx + browSpread, y: browY - 6)
                )
                let browColor: Color = region == "brows" ? Color.brandPrimary : Color.ivory.opacity(0.6)
                let browWidth: CGFloat = region == "brows" ? 3.0 : 1.4
                ctx.stroke(browsPath, with: .color(browColor), lineWidth: browWidth)

                let eyeY = faceTop + faceH * 0.34
                let eyeSpread = faceW * 0.22
                let eyeRx: CGFloat = faceW * 0.10
                let eyeRy: CGFloat = faceH * 0.048
                let eyeColor: Color = region == "eyes" ? Color.brandPrimary.opacity(0.9) : Color.ivory.opacity(0.55)
                let leftEyeRect = CGRect(x: cx - eyeSpread - eyeRx, y: eyeY - eyeRy, width: eyeRx * 2, height: eyeRy * 2)
                let rightEyeRect = CGRect(x: cx + eyeSpread - eyeRx, y: eyeY - eyeRy, width: eyeRx * 2, height: eyeRy * 2)
                ctx.stroke(Path(ellipseIn: leftEyeRect), with: .color(eyeColor), lineWidth: region == "eyes" ? 1.8 : 1.0)
                ctx.stroke(Path(ellipseIn: rightEyeRect), with: .color(eyeColor), lineWidth: region == "eyes" ? 1.8 : 1.0)

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

                let mouthY = faceTop + faceH * 0.71
                let mouthW = faceW * 0.22
                var mouthPath = Path()
                mouthPath.move(to: CGPoint(x: cx - mouthW, y: mouthY))
                mouthPath.addQuadCurve(
                    to: CGPoint(x: cx + mouthW, y: mouthY),
                    control: CGPoint(x: cx, y: mouthY + 5)
                )
                ctx.stroke(mouthPath, with: .color(Color.ivory.opacity(0.4)), lineWidth: 0.9)

                var centerLine = Path()
                centerLine.move(to: CGPoint(x: cx, y: faceTop + faceH * 0.04))
                centerLine.addLine(to: CGPoint(x: cx, y: faceTop + faceH * 0.22))
                ctx.stroke(
                    centerLine,
                    with: .color(Color.ivory.opacity(0.12)),
                    style: StrokeStyle(lineWidth: 0.5, dash: [3, 4])
                )

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
