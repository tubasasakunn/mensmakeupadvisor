import SwiftUI

struct HowtoShadowAnimation: View {
    private struct BrushStroke {
        let path: Path
        let width: CGFloat
    }

    private let strokes: [BrushStroke] = [
        // 左フェイスライン（太）
        .init(path: Path { p in
            p.move(to: .init(x: 140, y: 260))
            p.addQuadCurve(to: .init(x: 160, y: 370), control: .init(x: 145, y: 290))
            p.addQuadCurve(to: .init(x: 230, y: 435), control: .init(x: 190, y: 390))
        }, width: 20),
        // 右フェイスライン（太）
        .init(path: Path { p in
            p.move(to: .init(x: 360, y: 260))
            p.addQuadCurve(to: .init(x: 340, y: 370), control: .init(x: 355, y: 290))
            p.addQuadCurve(to: .init(x: 270, y: 435), control: .init(x: 310, y: 390))
        }, width: 20),
        // 鼻筋左（細）
        .init(path: Path { p in
            p.move(to: .init(x: 230, y: 205))
            p.addQuadCurve(to: .init(x: 225, y: 285), control: .init(x: 225, y: 245))
        }, width: 12),
        // 鼻筋右（細）
        .init(path: Path { p in
            p.move(to: .init(x: 270, y: 205))
            p.addQuadCurve(to: .init(x: 275, y: 285), control: .init(x: 275, y: 245))
        }, width: 12),
    ]

    private let strokeColor = Color(red: 0.365, green: 0.227, blue: 0.161)
    private let maxOpacity: Double = 0.6

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = HowtoLoop.progress(ctx.date)
            let trim = HowtoKeyframes.value(at: t, stops: [
                (0.00, 0), (0.05, 0), (0.50, 1), (1.00, 1)
            ])
            let opacity = HowtoKeyframes.value(at: t, stops: [
                (0.00, 0), (0.05, 0), (0.10, maxOpacity),
                (0.75, maxOpacity), (0.80, 0), (1.00, 0)
            ])

            ZStack {
                Image("howto_face_plain")
                    .resizable()
                    .scaledToFit()

                HowtoScaledOverlay {
                    ForEach(strokes.indices, id: \.self) { i in
                        strokes[i].path
                            .trim(from: 0, to: trim)
                            .stroke(strokeColor, style: .init(lineWidth: strokes[i].width, lineCap: .round))
                            .blur(radius: 6)
                            .opacity(opacity)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    HowtoShadowAnimation()
        .frame(width: 260, height: 260)
        .background(Color.gray.opacity(0.1))
}
