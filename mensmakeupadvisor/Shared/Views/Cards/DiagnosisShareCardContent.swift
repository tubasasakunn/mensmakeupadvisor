import SwiftUI

private enum Layout {
    nonisolated static let barTrack: CGFloat = 60
}

extension DiagnosisShareCardView {
    var scoreWithGrade: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL SCORE")
                    .font(Theme.Typography.Data.miniRegular)
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(result.totalScore)")
                        .font(Theme.Typography.Display.jumboXXLLight)
                        .italic()
                        .foregroundStyle(Color.ivory)

                    Text("/ 100")
                        .font(Theme.Typography.Data.largeLight)
                        .foregroundStyle(Color.inkSecondary)
                        .padding(.bottom, 8)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(result.gradeDescription)
                    .font(Theme.Typography.Data.miniRegular)
                    .foregroundStyle(result.gradeColor.opacity(0.8))
                    .kerning(0.5)
                    .padding(.bottom, 4)
            }
        }
    }

    var faceShapeBlock: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("FACE SHAPE")
                .font(Theme.Typography.Data.miniRegular)
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)

            Text(result.faceShape.label)
                .font(Theme.Typography.Display.titleBold)
                .italic()
                .foregroundStyle(Color.ivory)
        }
    }

    var topScoresList: some View {
        VStack(spacing: 10) {
            ForEach(result.scores.prefix(3)) { score in
                HStack {
                    Text(score.name)
                        .font(Theme.Typography.UI.captionRegular)
                        .foregroundStyle(Color.inkSecondary)

                    Spacer()

                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.lineColor)
                        Capsule()
                            .fill(score.gradeColor.opacity(0.8))
                            .frame(width: Layout.barTrack * CGFloat(score.score) / 100.0)
                    }
                    .frame(width: Layout.barTrack, height: Theme.Size.Stroke.regular)
                    .padding(.horizontal, 8)

                    Text(score.grade)
                        .font(Theme.Typography.Display.calloutLight)
                        .italic()
                        .foregroundStyle(score.gradeColor)
                        .frame(minWidth: Theme.Size.Column.narrow, alignment: .trailing)
                }
            }
        }
    }

    var bottomBar: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MensMakeupAdvisor")
                    .font(Theme.Typography.Data.smallSemibold)
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .kerning(1)
                Text("あなたは何点？/ What's yours?")
                    .font(Theme.Typography.Data.miniRegular)
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(0.5)
            }
            Spacer()

            Text(result.grade)
                .font(Theme.Typography.Data.baseBlack)
                .foregroundStyle(result.gradeColor)
        }
    }

}
