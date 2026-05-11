import SwiftUI

struct HowtoHighlightAnimation: View {
    private struct Spot {
        let cx: CGFloat, cy: CGFloat
        let rx: CGFloat, ry: CGFloat   // 楕円対応のため半径を 2 値で持つ
        let ringMaxScale: Double       // タップ波紋の最終スケール
        let phase: Double              // ポンと置く瞬間（0..1）
    }

    private let spots: [Spot] = [
        .init(cx: 250, cy: 130, rx: 35, ry: 35, ringMaxScale: 1.5, phase: 0.03),  // おでこ
        .init(cx: 160, cy: 270, rx: 30, ry: 30, ringMaxScale: 1.5, phase: 0.09),  // 左頬骨
        .init(cx: 340, cy: 270, rx: 30, ry: 30, ringMaxScale: 1.5, phase: 0.17),  // 右頬骨
        .init(cx: 250, cy: 240, rx: 18, ry: 45, ringMaxScale: 1.4, phase: 0.25),  // 鼻筋
        .init(cx: 250, cy: 380, rx: 25, ry: 25, ringMaxScale: 1.5, phase: 0.33),  // あご先
    ]

    private let sparklePositions: [CGPoint] = [
        .init(x: 270, y: 110),
        .init(x: 140, y: 250),
        .init(x: 360, y: 250),
        .init(x: 265, y: 220),
        .init(x: 265, y: 395),
    ]

    private let highlightGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 1.0, blue: 0.95, opacity: 0.95),
            Color(red: 1.0, green: 0.92, blue: 0.6,  opacity: 0.55),
        ],
        startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = HowtoLoop.progress(ctx.date)
            ZStack {
                Image("howto_face_plain")
                    .resizable()
                    .scaledToFit()

                HowtoScaledOverlay {
                    ForEach(spots.indices, id: \.self) { i in
                        ringView(spot: spots[i], t: t)
                    }
                    ForEach(spots.indices, id: \.self) { i in
                        markView(spot: spots[i], t: t)
                    }
                    ForEach(sparklePositions.indices, id: \.self) { i in
                        sparkleView(at: sparklePositions[i], t: t)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func markView(spot: Spot, t: Double) -> some View {
        // 出現タイミングからの相対進捗
        let p = spot.phase
        let opacity = HowtoKeyframes.value(at: t, stops: [
            (0.00, 0), (max(p - 0.03, 0), 0), (p, 1), (0.75, 1), (0.80, 0), (1.00, 0)
        ])
        let scale = HowtoKeyframes.value(at: t, stops: [
            (0.00, 0.6), (max(p - 0.03, 0), 0.6), (p, 1.1),
            (min(p + 0.03, 1), 1.0), (0.75, 1.0), (0.80, 0.8), (1.00, 0.8)
        ])
        return Ellipse()
            .fill(highlightGradient)
            .frame(width: spot.rx * 2, height: spot.ry * 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(x: spot.cx, y: spot.cy)
            .blendMode(.plusLighter)
    }

    // タップ瞬間に広がる波紋リング
    private func ringView(spot: Spot, t: Double) -> some View {
        let p = spot.phase
        let opacity = HowtoKeyframes.value(at: t, stops: [
            (0.00, 0), (max(p - 0.04, 0), 0), (max(p - 0.01, 0), 0.8),
            (min(p + 0.03, 1), 0), (1.00, 0)
        ])
        let scale = HowtoKeyframes.value(at: t, stops: [
            (0.00, 0.5), (max(p - 0.04, 0), 0.5), (max(p - 0.01, 0), 0.9),
            (min(p + 0.03, 1), spot.ringMaxScale), (1.00, spot.ringMaxScale)
        ])
        return Ellipse()
            .stroke(Color(red: 1.0, green: 0.961, blue: 0.616), lineWidth: 4)
            .frame(width: spot.rx * 2, height: spot.ry * 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(x: spot.cx, y: spot.cy)
    }

    // 4 点星のキラキラ（38%-80% で同期して光る）
    private func sparkleView(at pt: CGPoint, t: Double) -> some View {
        let opacity = HowtoKeyframes.value(at: t, stops: [
            (0.00, 0), (0.38, 0), (0.43, 1), (0.48, 0.8), (0.75, 0.8), (0.80, 0), (1.00, 0)
        ])
        let scale = HowtoKeyframes.value(at: t, stops: [
            (0.00, 0), (0.38, 0), (0.43, 1.2), (0.48, 1.0), (0.75, 1.0), (0.80, 0), (1.00, 0)
        ])
        let rotation = HowtoKeyframes.value(at: t, stops: [
            (0.00, 0), (0.38, 0), (0.43, 90), (0.48, 180), (0.75, 180), (0.80, 180), (1.00, 180)
        ])
        return SparkleShape()
            .fill(Color.white)
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .opacity(opacity)
            .position(x: pt.x, y: pt.y)
    }
}

// SVG: M 0,-12 Q 0,0 12,0 Q 0,0 0,12 Q 0,0 -12,0 Q 0,0 0,-12（4 点星）
private struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        p.move(to: .init(x: cx, y: cy - r))
        p.addQuadCurve(to: .init(x: cx + r, y: cy), control: .init(x: cx, y: cy))
        p.addQuadCurve(to: .init(x: cx, y: cy + r), control: .init(x: cx, y: cy))
        p.addQuadCurve(to: .init(x: cx - r, y: cy), control: .init(x: cx, y: cy))
        p.addQuadCurve(to: .init(x: cx, y: cy - r), control: .init(x: cx, y: cy))
        return p
    }
}

#Preview {
    HowtoHighlightAnimation()
        .frame(width: 260, height: 260)
        .background(Color.gray.opacity(0.1))
}
