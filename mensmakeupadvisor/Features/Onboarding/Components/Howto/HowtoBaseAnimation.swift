import SwiftUI

struct HowtoBaseAnimation: View {
    private struct Dot {
        let x: CGFloat, y: CGFloat, r: CGFloat
        let phase: Double  // 出現タイミングの遅れ（0..1）
    }

    private struct Arrow {
        let from: CGPoint
        let to: CGPoint
        let control: CGPoint
    }

    private let dots: [Dot] = [
        .init(x: 250, y: 160, r: 10, phase: 0.00),
        .init(x: 180, y: 275, r: 10, phase: 0.05),
        .init(x: 320, y: 275, r: 10, phase: 0.10),
        .init(x: 250, y: 290, r: 8,  phase: 0.15),
        .init(x: 250, y: 375, r: 9,  phase: 0.20),
    ]

    private let arrows: [Arrow] = [
        .init(from: .init(x: 250, y: 160), to: .init(x: 190, y: 120), control: .init(x: 220, y: 130)),
        .init(from: .init(x: 250, y: 160), to: .init(x: 310, y: 120), control: .init(x: 280, y: 130)),
        .init(from: .init(x: 180, y: 275), to: .init(x: 120, y: 230), control: .init(x: 150, y: 250)),
        .init(from: .init(x: 320, y: 275), to: .init(x: 380, y: 230), control: .init(x: 350, y: 250)),
        .init(from: .init(x: 250, y: 290), to: .init(x: 250, y: 230), control: .init(x: 250, y: 260)),
        .init(from: .init(x: 250, y: 375), to: .init(x: 250, y: 435), control: .init(x: 250, y: 405)),
    ]

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = HowtoLoop.progress(ctx.date)
            ZStack {
                Image("howto_face_plain")
                    .resizable()
                    .scaledToFit()

                HowtoScaledOverlay {
                    ForEach(arrows.indices, id: \.self) { i in
                        arrowView(arrow: arrows[i], t: t)
                    }
                    ForEach(dots.indices, id: \.self) { i in
                        dotView(dot: dots[i], t: t)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func dotView(dot: Dot, t: Double) -> some View {
        let local = (t - dot.phase + 1).truncatingRemainder(dividingBy: 1)
        let opacity = HowtoKeyframes.value(at: local, stops: [
            (0.00, 0), (0.05, 1), (0.75, 1), (0.80, 0), (1.00, 0)
        ])
        let scale = HowtoKeyframes.value(at: local, stops: [
            (0.00, 0), (0.05, 1.2), (0.08, 1), (0.75, 1), (0.80, 0), (1.00, 0)
        ])
        return Circle()
            .fill(Color(red: 0.913, green: 0.118, blue: 0.388))
            .frame(width: dot.r * 2, height: dot.r * 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(x: dot.x, y: dot.y)
    }

    // 矢印は trim で「点から外側へ」描く paint-on、先端に矢じりを重ねる
    private func arrowView(arrow: Arrow, t: Double) -> some View {
        let trimEnd = HowtoKeyframes.value(at: t, stops: [
            (0.00, 0), (0.25, 0), (0.40, 1), (1.00, 1)
        ])
        let opacity = HowtoKeyframes.value(at: t, stops: [
            (0.00, 0), (0.24, 0), (0.25, 1), (0.75, 1), (0.80, 0), (1.00, 0)
        ])
        // 先端の矢じりは線が末端付近まで描かれたタイミングで現れる
        let headReveal = HowtoKeyframes.value(at: trimEnd, stops: [(0, 0), (0.9, 0), (1.0, 1)])
        // quadCurve の t=1 における進行方向ベクトル = 2*(to - control)
        let dx = arrow.to.x - arrow.control.x
        let dy = arrow.to.y - arrow.control.y
        let angle = Angle(radians: atan2(dy, dx))
        let color = Color(red: 0, green: 0.737, blue: 0.831)

        return ZStack {
            Path { p in
                p.move(to: arrow.from)
                p.addQuadCurve(to: arrow.to, control: arrow.control)
            }
            .trim(from: 0, to: trimEnd)
            .stroke(color, style: .init(lineWidth: 5, lineCap: .round))

            ArrowTipShape()
                .fill(color)
                .frame(width: 12, height: 10)
                .rotationEffect(angle)
                .position(x: arrow.to.x, y: arrow.to.y)
                .opacity(headReveal)
        }
        .opacity(opacity)
    }
}

// 右向きに尖った二等辺三角形（rotationEffect で進行方向に向ける）
private struct ArrowTipShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    HowtoBaseAnimation()
        .frame(width: 260, height: 260)
        .background(Color.gray.opacity(0.1))
}
