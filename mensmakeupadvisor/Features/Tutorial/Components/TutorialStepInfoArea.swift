import SwiftUI

// Tutorial の各ステップの本文エリア。
// 強度スライダーはその step の部位だけを調整する。眉ステップは type picker。
struct TutorialStepInfoArea: View {
    let currentStep: TutorialStep
    @Binding var intensity: Double
    @Binding var eyebrowType: EyebrowApplier.BrowType?

    var body: some View {
        // Glass の白っぽい下敷きを外し、本文を LuxeBackground 上で素読みさせる。
        VStack(alignment: .leading, spacing: 0) {
            headerBlock
            divider
            oneLinerText
            explanationText
            controlBlock
                .padding(.top, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("STEP \(String(format: "%02d", currentStep.tagNumeric)) · \(currentStep.layer.labelJP)")
                .font(Theme.Typography.Data.smallMedium)
                .kerning(2)
                .foregroundStyle(Theme.Text.secondaryFaded)

            Text(currentStep.titleJP)
                .font(Theme.Typography.Display.titleLBold)
                .italic()
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)
        }
        .aid("tutorial_step_info")
    }

    private var divider: some View {
        HairlineDivider()
            .padding(.vertical, Theme.Spacing.md)
    }

    private var oneLinerText: some View {
        Text(currentStep.oneLiner)
            .font(Theme.Typography.Display.footnoteSemibold)
            .italic()
            .foregroundStyle(Theme.Text.primarySoft)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, Theme.Spacing.md)
    }

    private var explanationText: some View {
        Text(currentStep.explanation)
            .font(Theme.Typography.UI.subheadlineRegular)
            .foregroundStyle(Theme.Text.primaryFaded)
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
    return ZStack {
        LuxeBackground()
        TutorialStepInfoArea(
            currentStep: TutorialStep.sequence(for: .marugao)[1],
            intensity: $intensity,
            eyebrowType: $brow
        )
        .padding(Theme.Spacing.xxl)
    }
}
