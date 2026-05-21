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
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Color.appBackground)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(result.gradeColor)
                    )
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
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.inkSecondary)

                    Text(result.faceShape.label)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.ivory)

                    // grade 色のバッジは ScoreRing 横で既に主張しているので、
                    // ここでは ivory ベースで text 階層に揃え、色を増やさない。
                    HStack(spacing: 5) {
                        Text(result.grade)
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Color.ivory)
                        Text("·")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.inkTertiary)
                        Text(result.gradeDescription)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Theme.Text.primaryFaded)
                    }

                    Text(result.rankPercentile)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.inkSecondary)
                }

                HairlineDivider()

                Text(result.faceShape.note)
                    .font(.system(size: 11, weight: .regular))
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
