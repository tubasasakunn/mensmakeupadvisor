import SwiftUI

struct ScoreCardView: View {
    let score: FaceScore
    let index: Int
    @State private var barProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "n°%02d", index + 1))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkTertiary)
                    .kerning(1)

                Text(score.name)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)

                Spacer()

                Text(score.grade)
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(score.gradeColor)
                    .frame(minWidth: 24, alignment: .trailing)

                Text("\(score.score)pt")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.lineColor)
                        .frame(height: 3)

                    Capsule()
                        .fill(score.gradeColor.opacity(0.8))
                        .frame(width: geo.size.width * barProgress, height: 3)
                        .animation(
                            .easeOut(duration: 0.8).delay(Double(index) * 0.07),
                            value: barProgress
                        )
                }
            }
            .frame(height: 3)

            Text(score.advice)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 18)
        .padding(.leading, score.score >= 75 ? 10 : 0)
        .overlay(alignment: .leading) {
            if score.score >= 75 {
                Rectangle()
                    .fill(score.gradeColor)
                    .frame(width: 2)
                    .offset(x: -10)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(Double(index) * 0.07)) {
                barProgress = Double(score.score) / 100.0
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        ScoreCardView(score: AnalysisResult.mock.scores[0], index: 0)
        ScoreCardView(score: AnalysisResult.mock.scores[1], index: 1)
    }
    .padding(.horizontal, 24)
    .background(Color.appBackground)
}
