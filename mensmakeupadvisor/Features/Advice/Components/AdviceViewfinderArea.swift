import SwiftUI

struct AdviceViewfinderArea: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.03))
                .frame(height: 280)

            Ellipse()
                .stroke(
                    style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                )
                .foregroundStyle(Color.ivory.opacity(0.3))
                .padding(32)

            viewfinderCorners

            VStack {
                Spacer()
                HStack {
                    Circle()
                        .fill(Color.brandPrimary)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.brandPrimary)
                        .kerning(2)
                }
                .padding(.bottom, 16)
            }

            Text("顔を枠内に合わせてください")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.lineColor, lineWidth: 1)
        )
    }

    private var viewfinderCorners: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let arm: CGFloat = 16
            let thick: CGFloat = 1.5

            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 8, y: 8 + arm))
                    p.addLine(to: CGPoint(x: 8, y: 8))
                    p.addLine(to: CGPoint(x: 8 + arm, y: 8))
                }
                .stroke(Color.ivory.opacity(0.6), lineWidth: thick)

                Path { p in
                    p.move(to: CGPoint(x: w - 8 - arm, y: 8))
                    p.addLine(to: CGPoint(x: w - 8, y: 8))
                    p.addLine(to: CGPoint(x: w - 8, y: 8 + arm))
                }
                .stroke(Color.ivory.opacity(0.6), lineWidth: thick)

                Path { p in
                    p.move(to: CGPoint(x: 8, y: h - 8 - arm))
                    p.addLine(to: CGPoint(x: 8, y: h - 8))
                    p.addLine(to: CGPoint(x: 8 + arm, y: h - 8))
                }
                .stroke(Color.ivory.opacity(0.6), lineWidth: thick)

                Path { p in
                    p.move(to: CGPoint(x: w - 8 - arm, y: h - 8))
                    p.addLine(to: CGPoint(x: w - 8, y: h - 8))
                    p.addLine(to: CGPoint(x: w - 8, y: h - 8 - arm))
                }
                .stroke(Color.ivory.opacity(0.6), lineWidth: thick)
            }
        }
    }
}

#Preview {
    AdviceViewfinderArea()
        .padding(24)
        .background(Color.appBackground)
}
