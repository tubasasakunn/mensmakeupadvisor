import SwiftUI

struct DiagnosisScoreListSection: View {
    let result: AnalysisResult

    var body: some View {
        VStack(spacing: 0) {
            if let best = result.strongestScore, let worst = result.weakestScore {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("STRONGEST")
                            .font(.system(size: 8, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.inkTertiary)
                            .kerning(1.5)
                        HStack(spacing: 4) {
                            Text(best.name)
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .italic()
                                .foregroundStyle(Color.ivory)
                            Text(best.grade)
                                .font(.system(size: 12, weight: .black, design: .serif))
                                .italic()
                                .foregroundStyle(best.gradeColor)
                        }
                    }

                    Spacer()

                    Rectangle()
                        .fill(Color.lineColor)
                        .frame(width: 1, height: 36)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("NEEDS CARE")
                            .font(.system(size: 8, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.inkTertiary)
                            .kerning(1.5)
                        HStack(spacing: 4) {
                            Text(worst.grade)
                                .font(.system(size: 12, weight: .black, design: .serif))
                                .italic()
                                .foregroundStyle(worst.gradeColor)
                            Text(worst.name)
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .italic()
                                .foregroundStyle(Color.ivory)
                        }
                    }
                }
                .padding(.vertical, 16)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.lineColor).frame(height: 1)
                }
            }

            HStack {
                Text("7 CRITERIA — DETAILED REPORT")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2.5)
                Spacer()
            }
            .padding(.top, 16)
            .padding(.bottom, 4)

            ForEach(Array(result.scores.enumerated()), id: \.element.id) { index, score in
                ScoreCardView(score: score, index: index)
            }
        }
        .aid("diagnosis_score_list")
    }
}

#Preview {
    DiagnosisScoreListSection(result: .mock)
        .padding(24)
        .background(Color.appBackground)
}
