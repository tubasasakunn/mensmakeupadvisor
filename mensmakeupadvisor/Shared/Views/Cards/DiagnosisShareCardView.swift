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
            // 顔写真 or プレースホルダー
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
            // 下部グラデーション（コンテンツへの自然な接続）
            .overlay(
                LinearGradient(
                    colors: [Color.appBackground, .clear],
                    startPoint: .bottom,
                    endPoint: .init(x: 0.5, y: 0.5)
                )
            )

            // ランクパーセンタイル（左下）
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

            // グレードバッジ（右下）
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

    // MARK: - Content

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

    private var scoreWithGrade: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL SCORE")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(result.totalScore)")
                        .font(.system(size: 64, weight: .light, design: .serif))
                        .italic()
                        .foregroundStyle(Color.ivory)

                    Text("/ 100")
                        .font(.system(size: 14, weight: .light, design: .monospaced))
                        .foregroundStyle(Color.inkSecondary)
                        .padding(.bottom, 8)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(result.gradeDescription)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(result.gradeColor.opacity(0.8))
                    .kerning(0.5)
                    .padding(.bottom, 4)
            }
        }
    }

    private var faceShapeBlock: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("FACE SHAPE")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)

            Text(result.faceShape.label)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
        }
    }

    private var thinLine: some View {
        Rectangle()
            .fill(Color.lineColor)
            .frame(height: 1)
    }

    private var topScoresList: some View {
        VStack(spacing: 10) {
            ForEach(result.scores.prefix(3)) { score in
                HStack {
                    Text(score.name)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.inkSecondary)

                    Spacer()

                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.lineColor)
                        Capsule()
                            .fill(score.gradeColor.opacity(0.8))
                            .frame(width: 60 * CGFloat(score.score) / 100.0)
                    }
                    .frame(width: 60, height: 2)
                    .padding(.horizontal, 8)

                    Text(score.grade)
                        .font(.system(size: 15, weight: .light, design: .serif))
                        .italic()
                        .foregroundStyle(score.gradeColor)
                        .frame(minWidth: 18, alignment: .trailing)
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MensMakeupAdvisor")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.ivory.opacity(0.7))
                    .kerning(1)
                Text("あなたは何点？/ What's yours?")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(0.5)
            }
            Spacer()

            // グレードカラーのアクセント
            Text(result.grade)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(result.gradeColor)
        }
    }
}

#Preview {
    DiagnosisShareCardView(result: .mock, capturedImage: nil)
}
