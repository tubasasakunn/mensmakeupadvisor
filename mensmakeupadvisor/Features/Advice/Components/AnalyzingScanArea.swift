import SwiftUI
import UIKit

struct AnalyzingScanArea: View {
    let capturedImage: UIImage?
    let scanY: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            capturedImageView
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appBackground.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.lineColor, lineWidth: 1)
                )

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.brandPrimary.opacity(0.6), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: scanY)
                .clipped()

            meshOverlay
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(height: 240)
        .clipped()
    }

    @ViewBuilder
    private var capturedImageView: some View {
        if let image = capturedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .saturation(0.0)
                .brightness(-0.1)
                .contrast(0.9)
        } else {
            Rectangle()
                .fill(Color.white.opacity(0.04))
        }
    }

    private var meshOverlay: some View {
        Canvas { context, size in
            let cols = 8
            let rows = 10
            let cellW = size.width / CGFloat(cols)
            let cellH = size.height / CGFloat(rows)

            for col in 0...cols {
                var path = Path()
                let x = CGFloat(col) * cellW
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(Color.ivory.opacity(0.08)), lineWidth: 0.5)
            }
            for row in 0...rows {
                var path = Path()
                let y = CGFloat(row) * cellH
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color.ivory.opacity(0.08)), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    AnalyzingScanArea(capturedImage: nil, scanY: 60)
        .padding(24)
        .background(Color.appBackground)
}
