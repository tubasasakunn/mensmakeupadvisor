import SwiftUI

struct DiagnosisScoreListSection: View {
    let result: AnalysisResult
    var capturedImage: UIImage? = nil

    var body: some View {
        VStack(spacing: 0) {
            if let best = result.strongestScore, let worst = result.weakestScore {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("いちばんの強み")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.inkSecondary)
                        HStack(spacing: 4) {
                            Text(best.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.ivory)
                            Text(best.grade)
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(best.gradeColor)
                        }
                    }

                    Spacer()

                    HairlineVDivider(height: 36)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("伸びしろ")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.inkSecondary)
                        HStack(spacing: 4) {
                            Text(worst.grade)
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(worst.gradeColor)
                            Text(worst.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.ivory)
                        }
                    }
                }
                .padding(.vertical, 16)
                .overlay(alignment: .bottom) {
                    HairlineDivider()
                }
            }

            HStack {
                Text("7 つの評価指標 — 詳細レポート")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
            }
            .padding(.top, 16)
            .padding(.bottom, 4)

            ForEach(Array(result.scores.enumerated()), id: \.element.id) { index, score in
                ScoreCardView(
                    score: score,
                    index: index,
                    capturedImage: capturedImage,
                    landmarks: result.landmarksNormalized
                )
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
