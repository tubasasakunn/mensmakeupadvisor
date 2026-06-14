import SwiftUI

struct DiagnosisScoreListSection: View {
    let result: AnalysisResult
    var capturedImage: UIImage? = nil

    var body: some View {
        VStack(spacing: 0) {
            if let best = result.strongestScore, let worst = result.weakestScore {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("いちばんの強み")
                            .font(Theme.Typography.UI.footnoteMedium)
                            .foregroundStyle(Color.inkSecondary)
                        HStack(spacing: Theme.Spacing.xs) {
                            Text(best.name)
                                .font(Theme.Typography.UI.calloutMedium)
                                .foregroundStyle(Color.ivory)
                            Text(best.grade)
                                .font(Theme.Typography.UI.bodyHeavy)
                                .foregroundStyle(best.gradeColor)
                        }
                    }

                    Spacer()

                    HairlineVDivider(height: 36)

                    Spacer()

                    VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                        Text("伸びしろ")
                            .font(Theme.Typography.UI.footnoteMedium)
                            .foregroundStyle(Color.inkSecondary)
                        HStack(spacing: Theme.Spacing.xs) {
                            Text(worst.grade)
                                .font(Theme.Typography.UI.bodyHeavy)
                                .foregroundStyle(worst.gradeColor)
                            Text(worst.name)
                                .font(Theme.Typography.UI.calloutMedium)
                                .foregroundStyle(Color.ivory)
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.lg)
                .overlay(alignment: .bottom) {
                    HairlineDivider()
                }
            }

            HStack {
                Text("7 つの評価指標 — 詳細レポート")
                    .font(Theme.Typography.UI.subheadlineMedium)
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
            }
            .padding(.top, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xs)

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
