import SwiftUI

struct ScoreRingView: View {
    let value: Int
    let size: CGFloat
    @State private var animatedValue: Int = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.lineColor, lineWidth: 1)

            tickMarks

            Circle()
                .trim(from: 0, to: CGFloat(animatedValue) / 100)
                .stroke(
                    Color.ivory,
                    style: StrokeStyle(lineWidth: 2, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
                .animation(.interpolatingSpring(duration: 1.4), value: animatedValue)

            // カウントアップはせず最終値を即表示（アニメ中の数値変化が視覚的に煩雑なため）
            VStack(spacing: 2) {
                Text("\(value)")
                    .font(.system(size: size * 0.30, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)

                Text("OF 100")
                    .font(.system(size: size * 0.07, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.interpolatingSpring(duration: 1.4)) {
                animatedValue = value
            }
        }
    }

    private var tickMarks: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 6
            for i in 0..<20 {
                let angle = Double(i) / 20.0 * 2 * .pi - .pi / 2
                let inner = radius - 4
                let x1 = center.x + cos(angle) * inner
                let y1 = center.y + sin(angle) * inner
                let x2 = center.x + cos(angle) * radius
                let y2 = center.y + sin(angle) * radius
                var path = Path()
                path.move(to: CGPoint(x: x1, y: y1))
                path.addLine(to: CGPoint(x: x2, y: y2))
                context.stroke(path, with: .color(Color.ivory.opacity(0.15)), lineWidth: 0.5)
            }
        }
    }
}

#Preview {
    ScoreRingView(value: 73, size: 160)
        .padding(40)
        .background(Color.appBackground)
}
