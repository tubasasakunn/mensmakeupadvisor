import SwiftUI
import UIKit

// 320×568 = 9:16 シェアカード (scale×3 → 960×1704px)
struct DiagnosisShareCardView: View {
    let result: AnalysisResult
    var capturedImage: UIImage? = nil

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

                facePhotoSection
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 0) {
                    scoreWithGrade
                        .padding(.top, 18)

                    faceShapeBlock
                        .padding(.top, 10)

                    thinLine.padding(.top, 18)

                    topScoresList.padding(.top, 12)

                    thinLine.padding(.top, 12)

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

    // MARK: - Face Photo Section

    private var facePhotoSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let img = capturedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                }
            }
            .frame(width: 320, height: 200)
            .clipped()
            .overlay(Color.appBackground.opacity(0.38))
            .overlay(faceMeshCanvas)
            .overlay(
                LinearGradient(
                    colors: [Color.appBackground, .clear],
                    startPoint: .bottom,
                    endPoint: .init(x: 0.5, y: 0.5)
                )
            )

            VStack(alignment: .leading, spacing: 2) {
                Spacer()
                Text(result.rankPercentile)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1)
                    .padding(.leading, 28)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(result.grade)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(Color.appBackground)
                .frame(width: 52, height: 52)
                .background(result.gradeColor)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .padding(.trailing, 28)
                .padding(.bottom, 10)
        }
        .frame(width: 320, height: 200)
    }

    private var faceMeshCanvas: some View {
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
                context.stroke(p, with: .color(Color.ivory.opacity(0.10)), lineWidth: 0.5)
            }
            for row in 0...rows {
                var p = Path()
                let y = CGFloat(row) * cellH
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(p, with: .color(Color.ivory.opacity(0.10)), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("M · M · A")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.brandPrimary)
                .kerning(2)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("PRE-MAKEUP BASELINE")
                    .font(.system(size: 7, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkTertiary)
                    .kerning(1.5)
                Text("FACE DIAGNOSIS")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)
            }
        }
    }
}

#Preview {
    DiagnosisShareCardView(result: .mock, capturedImage: nil)
}
