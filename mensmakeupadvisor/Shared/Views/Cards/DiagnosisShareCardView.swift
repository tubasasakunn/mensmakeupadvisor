import SwiftUI
import UIKit

// 320×568 = 9:16 シェアカード (scale×3 → 960×1704px)
// 顔写真は載せず、検出したランドマークから描いた face mesh と
// 7 指標の数値だけで「素顔の構造」を語る。プライバシー上の懸念も避けつつ
// 「これは私の分析結果」として晒しても抵抗が少ない見せ方にする。
struct DiagnosisShareCardView: View {
    let result: AnalysisResult

    var body: some View {
        ZStack {
            Color.appBackground

            gridTexture

            Rectangle()
                .stroke(Color.lineColor, lineWidth: 0.5)

            VStack(alignment: .leading, spacing: 0) {
                topBar
                    .padding(.top, 28)
                    .padding(.horizontal, 28)

                faceMeshSection
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 0) {
                    scoreWithGrade
                        .padding(.top, 18)

                    faceShapeBlock
                        .padding(.top, 10)

                    HairlineDivider().padding(.top, 18)

                    topScoresList.padding(.top, 12)

                    HairlineDivider().padding(.top, 12)

                    Spacer(minLength: 10)

                    bottomBar.padding(.bottom, 28)
                }
                .padding(.horizontal, 28)
            }
        }
        .frame(width: 320, height: 568)
    }

    // MARK: - Background

    private var gridTexture: some View {
        Canvas { context, size in
            let step: CGFloat = 28
            for col in stride(from: CGFloat(0), through: size.width, by: step) {
                var p = Path()
                p.move(to: CGPoint(x: col, y: 0))
                p.addLine(to: CGPoint(x: col, y: size.height))
                context.stroke(p, with: .color(.white.opacity(0.025)), lineWidth: 0.5)
            }
            for row in stride(from: CGFloat(0), through: size.height, by: step) {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: row))
                p.addLine(to: CGPoint(x: size.width, y: row))
                context.stroke(p, with: .color(.white.opacity(0.025)), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Face Mesh Section

    // 320×200 の暗色プレートに、検出済み landmarks の wireframe だけを描く。
    // 顔の縦横比に合わせて mesh を contentMode: .fit で配置し、写真は載せない。
    private var faceMeshSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(Theme.Surface.glassWeak)

            meshCanvas
                .padding(20)

            VStack(alignment: .leading, spacing: 2) {
                Spacer()
                Text(result.rankPercentile)
                    .font(Theme.Typography.Data.miniMedium)
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1)
                    .padding(.leading, 28)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(result.grade)
                .font(Theme.Typography.Data.heroBlack)
                .foregroundStyle(Color.appBackground)
                .frame(width: 52, height: 52)
                .background(result.gradeColor)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .padding(.trailing, 28)
                .padding(.bottom, 10)
        }
        .frame(width: 320, height: 200)
        .clipped()
        .overlay(
            LinearGradient(
                colors: [Color.appBackground, .clear],
                startPoint: .bottom,
                endPoint: .init(x: 0.5, y: 0.6)
            )
            .allowsHitTesting(false)
        )
    }

    @ViewBuilder
    private var meshCanvas: some View {
        if let landmarks = result.landmarksNormalized, !landmarks.isEmpty {
            FaceMeshWireframe(landmarks: landmarks, aspect: meshAspect)
                .aspectRatio(meshAspect, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            placeholderGrid
        }
    }

    // 顔画像のアスペクト比 (撮影画像のもの)。情報がなければ 4:5 を仮置き。
    private var meshAspect: CGFloat {
        let w = result.imageWidthPx ?? 0
        let h = result.imageHeightPx ?? 0
        guard w > 0, h > 0 else { return 4.0 / 5.0 }
        return CGFloat(w) / CGFloat(h)
    }

    private var placeholderGrid: some View {
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
                context.stroke(p, with: .color(Theme.Mesh.wireSubtle), lineWidth: 0.5)
            }
            for row in 0...rows {
                var p = Path()
                let y = CGFloat(row) * cellH
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(p, with: .color(Theme.Mesh.wireSubtle), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("M · M · A")
                .font(Theme.Typography.Data.smallMedium)
                .foregroundStyle(Color.brandPrimary)
                .kerning(2)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("PRE-MAKEUP BASELINE")
                    .font(Theme.Typography.Data.microRegular)
                    .foregroundStyle(Color.inkTertiary)
                    .kerning(1.5)
                Text("FACE DIAGNOSIS")
                    .font(Theme.Typography.Data.miniRegular)
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)
            }
        }
    }
}

// MARK: - Mesh wireframe (landmarks-based)

// シェアカード用に切り出した face mesh 描画。
// DiagnosisFaceMeshPlate と同じ tesselation edges を共有する。
private struct FaceMeshWireframe: View {
    let landmarks: [CGPoint]
    let aspect: CGFloat

    var body: some View {
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
                let r: CGFloat = 0.8
                let rect = CGRect(
                    x: p.x * size.width - r, y: p.y * size.height - r,
                    width: r * 2, height: r * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(Theme.Mesh.landmarkDot))
            }
        }
        .allowsHitTesting(false)
    }

    // static let は Swift ランタイムが 1 回限りスレッドセーフに初期化するので
    // 別途ロックも nonisolated(unsafe) も不要。
    private static let cachedEdges: [(Int, Int)] = FaceMeshResources.tesselationConnections()
}

#Preview {
    DiagnosisShareCardView(result: .mock)
}
