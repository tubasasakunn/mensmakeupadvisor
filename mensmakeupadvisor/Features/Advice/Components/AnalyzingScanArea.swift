import SwiftUI
import UIKit

struct AnalyzingScanArea: View {
    let capturedImage: UIImage?
    let scanY: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            capturedImageView
                .frame(height: Theme.Size.Canvas.scan)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xs))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.xs)
                        .fill(Theme.Surface.imageDim)
                )
                .hairlineBorder(cornerRadius: Theme.Radius.xs)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Theme.Plate.scanLineGlow, Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: Theme.Size.Stroke.regular)
                .offset(y: scanY)
                .clipped()

            meshOverlay
                .frame(height: Theme.Size.Canvas.scan)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xs))
        }
        .frame(height: Theme.Size.Canvas.scan)
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
                .fill(Theme.Surface.glassWeak)
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
                context.stroke(path, with: .color(Theme.Plate.scanGridLine), lineWidth: Theme.Size.Line.thin)
            }
            for row in 0...rows {
                var path = Path()
                let y = CGFloat(row) * cellH
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Theme.Plate.scanGridLine), lineWidth: Theme.Size.Line.thin)
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
