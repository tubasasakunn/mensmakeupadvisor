import SwiftUI
import UIKit

struct DiagnosisHeroSection: View {
    let result: AnalysisResult
    @State private var gradeBadgeVisible = false

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            ZStack(alignment: .bottomTrailing) {
                ScoreRingView(value: result.totalScore, size: 160)
                    .aid("diagnosis_score_ring")

                Text(result.grade)
                    .font(.system(size: 17, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.appBackground)
                    .frame(width: 44, height: 44)
                    .background(result.gradeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .shadow(color: result.gradeColor.opacity(0.5), radius: 8, x: 0, y: 2)
                    .offset(x: 8, y: 8)
                    .opacity(gradeBadgeVisible ? 1 : 0)
                    .scaleEffect(gradeBadgeVisible ? 1 : 0.4)
                    .onAppear {
                        withAnimation(.spring(duration: 0.5, bounce: 0.4).delay(1.5)) {
                            gradeBadgeVisible = true
                        }
                    }
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FACE SHAPE")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.inkSecondary)
                        .kerning(2)

                    Text(result.faceShape.label)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .italic()
                        .foregroundStyle(Color.ivory)

                    HStack(spacing: 5) {
                        Text(result.grade)
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(result.gradeColor)
                        Text("·")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.inkTertiary)
                        Text(result.gradeDescription)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(result.gradeColor.opacity(0.9))
                            .kerning(0.5)
                    }

                    Text(result.rankPercentile)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.inkSecondary)
                        .kerning(1)
                }

                Rectangle()
                    .fill(Color.lineColor)
                    .frame(height: 1)

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
