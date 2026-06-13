import SwiftUI
import UIKit

struct DiagnosisSharePrompt: View {
    let result: AnalysisResult
    @State private var isRendering = false

    var body: some View {
        Button {
            Task { await shareResult() }
        } label: {
            HStack(spacing: Theme.Spacing.lg) {
                miniCardPreview
                    .frame(width: 68, height: 88)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("結果をシェアする")
                        .font(Theme.Typography.Display.calloutSemibold)
                        .italic()
                        .foregroundStyle(Color.ivory)
                    Text("素顔のスコア — あなたは何点？")
                        .font(Theme.Typography.UI.subheadline)
                        .foregroundStyle(Theme.Text.primaryFaded)
                }

                Spacer()

                if isRendering {
                    ProgressView().tint(Color.ivory).scaleEffect(0.7)
                        .frame(width: 40, height: 40)
                } else {
                    // 親が glassEffect を持つので、ここでは glass を重ねず
                    // 塗りつぶしの円のみ。grade 色ではなく bordeaux 固定で
                    // 「シェア = アクション」を一義に示す。
                    Image(systemName: "arrow.up.forward")
                        .font(Theme.Typography.UI.bodyLargeSemibold)
                        .foregroundStyle(Color.ivory)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Theme.Accent.primary))
                }
            }
            .padding(Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .aid("diagnosis_share_button")
        .disabled(isRendering)
    }

    private var miniCardPreview: some View {
        ZStack {
            Theme.Surface.raised

            VStack(spacing: 0) {
                Text("M·M·A")
                    .font(Theme.Typography.Data.nanoMedium)
                    .foregroundStyle(Theme.Text.secondary)
                    .padding(.top, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(result.totalScore)")
                        .font(Theme.Typography.Display.title2Light)
                        .italic()
                        .foregroundStyle(Color.ivory)
                    Spacer()
                    Text(result.grade)
                        .font(Theme.Typography.Display.labelBlack)
                        .italic()
                        .foregroundStyle(result.gradeColor)
                }
                .padding(.horizontal, 6)

                HairlineDivider(height: 0.5)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)

                Text(result.faceShape.label)
                    .font(Theme.Typography.Display.miniBold)
                    .italic()
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .hairlineBorder(Color.lineStrong, cornerRadius: 2, lineWidth: 0.5)
    }

    private func shareResult() async {
        isRendering = true
        defer { isRendering = false }
        let card = DiagnosisShareCardView(result: result)
        if let image = ShareHelper.render(card) {
            ShareHelper.present([image])
        }
    }
}

#Preview {
    DiagnosisSharePrompt(result: .mock)
        .padding(24)
        .background(Color.appBackground)
}
