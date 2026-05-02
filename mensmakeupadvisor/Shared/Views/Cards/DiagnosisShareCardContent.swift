import SwiftUI

extension DiagnosisShareCardView {
    var scoreWithGrade: some View {
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

    var faceShapeBlock: some View {
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

    var topScoresList: some View {
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

    var bottomBar: some View {
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

            Text(result.grade)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(result.gradeColor)
        }
    }

    var thinLine: some View {
        Rectangle()
            .fill(Color.lineColor)
            .frame(height: 1)
    }
}
