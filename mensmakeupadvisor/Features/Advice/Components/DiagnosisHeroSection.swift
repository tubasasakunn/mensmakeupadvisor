import SwiftUI
import UIKit

struct DiagnosisHeroSection: View {
    let result: AnalysisResult
    @State private var gradeBadgeVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            ZStack(alignment: .bottomTrailing) {
                ScoreRingView(value: result.totalScore, size: 160)
                    .aid("diagnosis_score_ring")

                Text(result.grade)
                    .font(Theme.Typography.UI.title3Heavy)
                    .foregroundStyle(Color.appBackground)
                    .frame(width: 44, height: 44)
                    .background(result.gradeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .shadow(color: result.gradeColor.opacity(0.5), radius: 8, x: 0, y: 2)
                    .offset(x: 8, y: 8)
                    .opacity(gradeBadgeVisible ? 1 : 0)
                    .scaleEffect(gradeBadgeVisible ? 1 : 0.4)
                    .accessibilityLabel("総合評価 \(result.grade)")
                    .onAppear {
                        if reduceMotion {
                            gradeBadgeVisible = true
                        } else {
                            withAnimation(.spring(duration: 0.5, bounce: 0.4).delay(1.5)) {
                                gradeBadgeVisible = true
                            }
                        }
                    }
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("顔型")
                        .font(Theme.Typography.UI.subheadlineMedium)
                        .foregroundStyle(Color.inkSecondary)

                    Text(result.faceShape.label)
                        .font(Theme.Typography.UI.titleBold)
                        .foregroundStyle(Color.ivory)

                    HStack(spacing: 5) {
                        // グレード文字だけ色を持たせ、説明文は中立色にする。
                        // バッジ・リング・文字で 3 重に色が乗ると煩いため。
                        Text(result.grade)
                            .font(Theme.Typography.UI.calloutHeavy)
                            .foregroundStyle(result.gradeColor)
                        Text("·")
                            .font(Theme.Typography.UI.subheadline)
                            .foregroundStyle(Color.inkTertiary)
                        Text(result.gradeDescription)
                            .font(Theme.Typography.UI.subheadlineRegular)
                            .foregroundStyle(Theme.Text.primarySoft)
                    }

                    Text(result.rankPercentile)
                        .font(Theme.Typography.UI.subheadlineMedium)
                        .foregroundStyle(Color.inkSecondary)
                }

                HairlineDivider()

                Text(result.faceShape.note)
                    .font(Theme.Typography.UI.footnoteRegular)
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    DiagnosisHeroSection(result: .mock)
        .padding(24)
        .background(Color.appBackground)
        .environment(AppState())
}
