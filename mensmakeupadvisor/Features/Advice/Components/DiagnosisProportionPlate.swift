import SwiftUI
import UIKit

// 三分割比率・五分割比率・目幅・口幅などの「比率」を撮影画像に重ねて見せる。
// 既存の DiagnosisFaceMeshPlate がメッシュ全体を見せるのに対し、
// こちらは判定の根拠を 1 枚で直感的に伝えるための補助図。
struct DiagnosisProportionPlate: View {
    let capturedImage: UIImage?
    let result: AnalysisResult?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                content(in: geo.size)
            }
            .aspectRatio(imageAspect, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.lineColor, lineWidth: 1)
            )

            captionLabel
                .padding(12)
        }
        .aspectRatio(imageAspect, contentMode: .fit)
        .aid("diagnosis_proportion_plate")
    }

    private var imageAspect: CGFloat {
        if let img = capturedImage, img.size.width > 0, img.size.height > 0 {
            return img.size.width / img.size.height
        }
        return 4.0 / 5.0
    }

    @ViewBuilder
    private func content(in size: CGSize) -> some View {
        ZStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .overlay(Color.appBackground.opacity(0.65))
            } else {
                Rectangle().fill(Color.white.opacity(0.08))
            }

            if let landmarks = result?.landmarksNormalized, landmarks.count >= 478 {
                proportionCanvas(landmarks: landmarks)
            }
        }
    }

    // 三分割線・五分割線・目幅・口幅
    private func proportionCanvas(landmarks: [CGPoint]) -> some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            func pt(_ id: Int) -> CGPoint {
                let p = landmarks[id]
                return CGPoint(x: p.x * w, y: p.y * h)
            }

            // ─── 三分割（縦比） ───
            // 額頂点〜眉間〜鼻下〜顎先 の3区画
            let foreheadY = pt(FaceLandmarkID.foreheadTop).y
            let glabellaY = pt(FaceLandmarkID.glabella).y
            let subnasalY = pt(FaceLandmarkID.subnasal).y
            let chinY     = pt(FaceLandmarkID.chinBottom).y

            let thirdsColor = Color.brandPrimary.opacity(0.85)
            for y in [foreheadY, glabellaY, subnasalY, chinY] {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: w, y: y))
                context.stroke(p, with: .color(thirdsColor), lineWidth: 0.8)
            }

            // 三分割ラベル（右端）
            let thirdLabels: [(CGFloat, String)] = [
                ((foreheadY + glabellaY) / 2, "① 額"),
                ((glabellaY + subnasalY) / 2, "② 中"),
                ((subnasalY + chinY) / 2, "③ 顎"),
            ]
            for (y, label) in thirdLabels {
                drawLabel(context: &context, text: label, at: CGPoint(x: w - 6, y: y), align: .trailing, color: thirdsColor)
            }

            // ─── 五分割（横比） ───
            // 左右テンプル間を、両目幅+目間+両目尻〜こめかみ で 5 等分する想定の理想と
            // 比較するため、実際の境界線 (こめかみ・目尻・目頭) を縦線で描画。
            let xs: [CGFloat] = [
                pt(FaceLandmarkID.templeR).x,
                pt(FaceLandmarkID.eyeOuterR).x,
                pt(FaceLandmarkID.eyeInnerR).x,
                pt(FaceLandmarkID.eyeInnerL).x,
                pt(FaceLandmarkID.eyeOuterL).x,
                pt(FaceLandmarkID.templeL).x,
            ]
            let fifthsColor = Color.sulphur.opacity(0.85)
            // 縦線は顔の高さ全体ではなく、額〜顎の範囲で描く
            for x in xs {
                var p = Path()
                p.move(to: CGPoint(x: x, y: foreheadY))
                p.addLine(to: CGPoint(x: x, y: chinY))
                context.stroke(p, with: .color(fifthsColor), lineWidth: 0.7)
            }

            // ─── 目幅・口幅・鼻幅 ───
            let highlight = Color.ivory.opacity(0.95)

            // 目幅（左右）
            drawRange(context: &context,
                      from: pt(FaceLandmarkID.eyeOuterR), to: pt(FaceLandmarkID.eyeInnerR),
                      color: highlight, label: "目幅R")
            drawRange(context: &context,
                      from: pt(FaceLandmarkID.eyeInnerL), to: pt(FaceLandmarkID.eyeOuterL),
                      color: highlight, label: "目幅L")

            // 口幅
            drawRange(context: &context,
                      from: pt(FaceLandmarkID.mouthR), to: pt(FaceLandmarkID.mouthL),
                      color: highlight, label: "口幅")

            // 鼻幅
            drawRange(context: &context,
                      from: pt(FaceLandmarkID.noseWingROut), to: pt(FaceLandmarkID.noseWingLOut),
                      color: highlight, label: "鼻幅")
        }
        .allowsHitTesting(false)
    }

    // 2点間に水平な短いマーカーラインを描く
    private func drawRange(context: inout GraphicsContext, from a: CGPoint, to b: CGPoint,
                           color: Color, label: String) {
        let y = (a.y + b.y) / 2
        var line = Path()
        line.move(to: CGPoint(x: a.x, y: y))
        line.addLine(to: CGPoint(x: b.x, y: y))
        context.stroke(line, with: .color(color), lineWidth: 1.2)

        // 両端の小さな縦バー
        for x in [a.x, b.x] {
            var bar = Path()
            bar.move(to: CGPoint(x: x, y: y - 4))
            bar.addLine(to: CGPoint(x: x, y: y + 4))
            context.stroke(bar, with: .color(color), lineWidth: 1.0)
        }

        drawLabel(context: &context, text: label,
                  at: CGPoint(x: (a.x + b.x) / 2, y: y - 6), align: .center, color: color)
    }

    private enum LabelAlign { case leading, center, trailing }

    private func drawLabel(context: inout GraphicsContext, text: String,
                           at point: CGPoint, align: LabelAlign, color: Color) {
        let t = Text(text)
            .font(.system(size: 8, weight: .semibold, design: .monospaced))
            .foregroundStyle(color)
        let resolved = context.resolve(t)
        let bounds = resolved.measure(in: CGSize(width: 200, height: 40))
        // SwiftUI Canvas の draw(_:at:) は center anchor がデフォルト
        let centerX: CGFloat = switch align {
        case .leading:  point.x + bounds.width / 2
        case .center:   point.x
        case .trailing: point.x - bounds.width / 2
        }
        context.draw(resolved, at: CGPoint(x: centerX, y: point.y))
    }

    private var captionLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("FIG. 02")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)
            Text("PROPORTIONS · 3RDS / 5THS")
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkTertiary)
                .kerning(1.5)
        }
    }
}

#Preview {
    DiagnosisProportionPlate(capturedImage: nil, result: nil)
        .padding(24)
        .background(Color.appBackground)
}
