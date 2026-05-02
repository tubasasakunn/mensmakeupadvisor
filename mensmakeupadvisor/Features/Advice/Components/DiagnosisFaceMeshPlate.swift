import SwiftUI
import UIKit

struct DiagnosisFaceMeshPlate: View {
    let capturedImage: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(Color.appBackground.opacity(0.45))
            .overlay(meshGridOverlay)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.lineColor, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("FIG. 01")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)
                Text("FACE MESH")
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkTertiary)
                    .kerning(1.5)
            }
            .padding(12)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var meshGridOverlay: some View {
        Canvas { context, size in
            let cols = 10
            let rows = 12
            let cellW = size.width / CGFloat(cols)
            let cellH = size.height / CGFloat(rows)

            for col in 0...cols {
                var p = Path()
                let x = CGFloat(col) * cellW
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(p, with: .color(Color.ivory.opacity(0.12)), lineWidth: 0.5)
            }
            for row in 0...rows {
                var p = Path()
                let y = CGFloat(row) * cellH
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(p, with: .color(Color.ivory.opacity(0.12)), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    DiagnosisFaceMeshPlate(capturedImage: nil)
        .padding(24)
        .background(Color.appBackground)
}
