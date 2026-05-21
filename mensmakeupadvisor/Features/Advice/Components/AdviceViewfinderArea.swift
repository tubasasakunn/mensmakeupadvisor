import SwiftUI

struct AdviceViewfinderArea: View {
    var body: some View {
        ZStack {
            Ellipse()
                .stroke(
                    style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                )
                .foregroundStyle(Theme.Plate.dashedEllipse)
                .padding(32)

            viewfinderCorners

            VStack {
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.brandPrimary)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.brandPrimary)
                        .kerning(2.5)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 6)
                .background { Capsule().fill(Theme.Surface.labelBackdrop) }
                .padding(.bottom, Theme.Spacing.lg)
            }

            Text("顔を枠内に合わせてください")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .kerning(1)
                .foregroundStyle(Theme.Text.primaryFaded)
        }
        .frame(height: 280)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.Surface.sunken)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.Line.outlineIvorySoft, lineWidth: 0.5)
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
                .stroke(Theme.Step.labelTag, lineWidth: thick)

                Path { p in
                    p.move(to: CGPoint(x: w - 8 - arm, y: 8))
                    p.addLine(to: CGPoint(x: w - 8, y: 8))
                    p.addLine(to: CGPoint(x: w - 8, y: 8 + arm))
                }
                .stroke(Theme.Step.labelTag, lineWidth: thick)

                Path { p in
                    p.move(to: CGPoint(x: 8, y: h - 8 - arm))
                    p.addLine(to: CGPoint(x: 8, y: h - 8))
                    p.addLine(to: CGPoint(x: 8 + arm, y: h - 8))
                }
                .stroke(Theme.Step.labelTag, lineWidth: thick)

                Path { p in
                    p.move(to: CGPoint(x: w - 8 - arm, y: h - 8))
                    p.addLine(to: CGPoint(x: w - 8, y: h - 8))
                    p.addLine(to: CGPoint(x: w - 8, y: h - 8 - arm))
                }
                .stroke(Theme.Step.labelTag, lineWidth: thick)
            }
        }
    }
}

#Preview {
    AdviceViewfinderArea()
        .padding(24)
        .background(Color.appBackground)
}
