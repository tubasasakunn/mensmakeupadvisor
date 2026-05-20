import SwiftUI

// Tutorial の各ステップの本文エリア。
// 強度スライダーはその step の部位だけを調整する。眉ステップは type picker。
struct TutorialStepInfoArea: View {
    let currentStep: TutorialStep
    @Binding var intensity: Double
    @Binding var eyebrowType: EyebrowApplier.BrowType?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBlock
            divider
            oneLinerText
            explanationText
            controlBlock
                .padding(.top, 22)
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ステップ \(currentStep.tagNumeric) · \(currentStep.layer.labelJP)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkSecondary)

            Text(currentStep.titleJP)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)
        }
        .aid("tutorial_step_info")
    }

    private var divider: some View {
        HairlineDivider()
            .padding(.vertical, 14)
    }

    private var oneLinerText: some View {
        Text(currentStep.oneLiner)
            .font(.system(size: 13, weight: .semibold, design: .serif))
            .italic()
            .foregroundStyle(Theme.Text.primarySoft)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 12)
    }

    private var explanationText: some View {
        Text(currentStep.explanation)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color.inkSecondary)
            .lineSpacing(6)
            .lineLimit(6)
            .minimumScaleFactor(0.85)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var controlBlock: some View {
        if currentStep.layer == .eyebrow {
            TutorialEyebrowPicker(eyebrowType: $eyebrowType,
                                  recommended: currentStep.areaName)
        } else {
            TutorialIntensitySlider(layer: currentStep.layer, value: $intensity)
        }
    }
}

#Preview {
    @Previewable @State var intensity: Double = 50
    @Previewable @State var brow: EyebrowApplier.BrowType? = .natural
    return TutorialStepInfoArea(
        currentStep: TutorialStep.sequence(for: .marugao)[1],
        intensity: $intensity,
        eyebrowType: $brow
    )
    .padding(28)
    .background(Color.appBackground)
}
