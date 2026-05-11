import SwiftUI

struct HowtoEyesAnimation: View {
    private struct EyeStroke {
        let from: CGPoint
        let to: CGPoint
        let control: CGPoint
        let width: CGFloat
        let color: Color
        let maxOpacity: Double
        let blur: CGFloat
        let drawStart: Double  // trim 0 -> 1 開始
        let drawEnd: Double    // trim 1 到達
        let fadeIn: Double     // opacity が maxOpacity に到達
    }

    private let eyeshadows: [EyeStroke] = [
        // 左目上
        .init(from: .init(x: 213, y: 220), to: .init(x: 165, y: 220), control: .init(x: 188, y: 195),
              width: 14, color: Color(red: 0.612, green: 0.482, blue: 0.439),
              maxOpacity: 0.45, blur: 4, drawStart: 0.05, drawEnd: 0.30, fadeIn: 0.10),
        // 右目上
        .init(from: .init(x: 287, y: 220), to: .init(x: 335, y: 220), control: .init(x: 312, y: 195),
              width: 14, color: Color(red: 0.612, green: 0.482, blue: 0.439),
              maxOpacity: 0.45, blur: 4, drawStart: 0.05, drawEnd: 0.30, fadeIn: 0.10),
    ]

    private let teardrops: [EyeStroke] = [
        // 左目下
        .init(from: .init(x: 202, y: 242), to: .init(x: 175, y: 242), control: .init(x: 192, y: 255),
              width: 2, color: Color(red: 0.129, green: 0.129, blue: 0.129),
              maxOpacity: 0.65, blur: 1, drawStart: 0.10, drawEnd: 0.35, fadeIn: 0.15),
        // 右目下
        .init(from: .init(x: 298, y: 242), to: .init(x: 325, y: 242), control: .init(x: 308, y: 255),
              width: 2, color: Color(red: 0.129, green: 0.129, blue: 0.129),
              maxOpacity: 0.65, blur: 1, drawStart: 0.10, drawEnd: 0.35, fadeIn: 0.15),
    ]

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = HowtoLoop.progress(ctx.date)
            ZStack {
                Image("howto_face_plain")
                    .resizable()
                    .scaledToFit()

                HowtoScaledOverlay {
                    ForEach(eyeshadows.indices, id: \.self) { i in
                        strokeView(s: eyeshadows[i], t: t)
                    }
                    ForEach(teardrops.indices, id: \.self) { i in
                        strokeView(s: teardrops[i], t: t)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func strokeView(s: EyeStroke, t: Double) -> some View {
        let trimEnd = HowtoKeyframes.value(at: t, stops: [
            (0.00, 0), (s.drawStart, 0), (s.drawEnd, 1), (1.00, 1)
        ])
        let opacity = HowtoKeyframes.value(at: t, stops: [
            (0.00, 0), (s.drawStart, 0), (s.fadeIn, s.maxOpacity),
            (0.75, s.maxOpacity), (0.80, 0), (1.00, 0)
        ])
        return Path { p in
            p.move(to: s.from)
            p.addQuadCurve(to: s.to, control: s.control)
        }
        .trim(from: 0, to: trimEnd)
        .stroke(s.color, style: .init(lineWidth: s.width, lineCap: .round))
        .blur(radius: s.blur)
        .opacity(opacity)
    }
}

#Preview {
    HowtoEyesAnimation()
        .frame(width: 260, height: 260)
        .background(Color.gray.opacity(0.1))
}
