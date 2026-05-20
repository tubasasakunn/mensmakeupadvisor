import SwiftUI
import UIKit

struct DiagnosisFaceMeshPlate: View {
    let capturedImage: UIImage?
    let result: AnalysisResult?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                meshContent(in: geo.size)
            }
            .aspectRatio(imageAspect, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.lineColor, lineWidth: 1)
            )

            captionLabel
                .padding(12)
        }
        .aspectRatio(imageAspect, contentMode: .fit)
        .aid("diagnosis_face_mesh_plate")
    }

    // 撮影画像のアスペクト比に合わせて Canvas と画像の表示サイズを揃え、
    // 正規化座標 (0-1) を単純に表示サイズへ写像できるようにする。
    private var imageAspect: CGFloat {
        if let img = capturedImage, img.size.width > 0, img.size.height > 0 {
            return img.size.width / img.size.height
        }
        return 4.0 / 5.0
    }

    @ViewBuilder
    private func meshContent(in size: CGSize) -> some View {
        ZStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .overlay(Theme.Surface.imageDim)
            } else {
                Rectangle().fill(Theme.Surface.glassMedium)
            }

            if let landmarks = result?.landmarksNormalized, !landmarks.isEmpty {
                faceMeshCanvas(landmarks: landmarks)
            } else {
                placeholderGrid
            }
        }
    }

    private func faceMeshCanvas(landmarks: [CGPoint]) -> some View {
        Canvas { context, size in
            let edges = Self.cachedEdges
            var meshPath = Path()
            for (a, b) in edges where a < landmarks.count && b < landmarks.count {
                let pa = landmarks[a]
                let pb = landmarks[b]
                meshPath.move(to: CGPoint(x: pa.x * size.width, y: pa.y * size.height))
                meshPath.addLine(to: CGPoint(x: pb.x * size.width, y: pb.y * size.height))
            }
            context.stroke(meshPath, with: .color(Theme.Diagram.highlightArea), lineWidth: 0.4)

            for p in landmarks {
                let r: CGFloat = 0.9
                let rect = CGRect(
                    x: p.x * size.width - r, y: p.y * size.height - r,
                    width: r * 2, height: r * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(Theme.Mesh.landmarkDot))
            }
        }
        .allowsHitTesting(false)
    }

    private var placeholderGrid: some View {
        Canvas { context, size in
            let cols = 10, rows = 12
            for col in 0...cols {
                var p = Path()
                let x = CGFloat(col) * size.width / CGFloat(cols)
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(p, with: .color(Theme.Mesh.placeholderGrid), lineWidth: 0.5)
            }
            for row in 0...rows {
                var p = Path()
                let y = CGFloat(row) * size.height / CGFloat(rows)
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(p, with: .color(Theme.Mesh.placeholderGrid), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }

    private var captionLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("図 1")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.inkSecondary)
            Text("顔メッシュ · 478 点")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.inkTertiary)
        }
    }

    nonisolated(unsafe) private static var cachedEdges: [(Int, Int)] = FaceMeshResources.tesselationConnections()
}

#Preview {
    DiagnosisFaceMeshPlate(capturedImage: nil, result: nil)
        .padding(24)
        .background(Color.appBackground)
}
