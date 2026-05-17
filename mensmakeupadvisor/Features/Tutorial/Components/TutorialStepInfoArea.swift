import SwiftUI

// Tutorial の各ステップの本文エリア。
// チップ (area 選択) は出さない (オンボーディングでは選択不要)、
// が強度スライダーは入れて、効果の見え方を比較しながら学べるようにする。
// 眉ステップは type picker。
struct TutorialStepInfoArea: View {
    let currentStep: TutorialStep
    @Binding var intensity: MakeupIntensity
    @Binding var eyebrowType: EyebrowApplier.BrowType?
    @Binding var showBeforeImage: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBlock
            divider
            oneLinerText
            explanationText
            controlBlock
                .padding(.top, 22)
            beforeButton
                .padding(.top, 16)
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ACT \(currentStep.tag) · \(currentStep.layer.labelJP.uppercased())")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)

            Text("\(currentStep.titleJP).")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)
        }
        .aid("tutorial_step_info")
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.lineColor)
            .frame(height: 1)
            .padding(.vertical, 14)
    }

    private var oneLinerText: some View {
        Text(currentStep.oneLiner)
            .font(.system(size: 13, weight: .semibold, design: .serif))
            .italic()
            .foregroundStyle(Color.ivory.opacity(0.92))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 12)
    }

    private var explanationText: some View {
        Text(currentStep.explanation)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color.inkSecondary)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var controlBlock: some View {
        if currentStep.layer == .eyebrow {
            TutorialEyebrowPicker(eyebrowType: $eyebrowType,
                                  recommended: currentStep.areaName)
        } else {
            TutorialIntensitySlider(layer: currentStep.layer,
                                    value: Binding(
                                        get: { intensity[currentStep.layer] },
                                        set: { intensity[currentStep.layer] = $0 }
                                    ))
        }
    }

    private var beforeButton: some View {
        Button {
            // ロングプレス想定。タップでも同じ振る舞いをガード
        } label: {
            Text("HOLD → BEFORE")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(showBeforeImage ? Color.appBackground : Color.ivory)
                .kerning(1.5)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(showBeforeImage ? Color.ivory : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.lineStrong, lineWidth: 1)
                )
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.1)
                .onChanged { _ in showBeforeImage = true }
                .onEnded { _ in showBeforeImage = false }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in showBeforeImage = false }
        )
        .aid("tutorial_before_button")
    }
}

#Preview {
    @Previewable @State var intensity = MakeupIntensity(base: 40, highlight: 50)
    @Previewable @State var brow: EyebrowApplier.BrowType? = .natural
    @Previewable @State var showBefore = false
    return TutorialStepInfoArea(
        currentStep: TutorialStep.sequence(for: .marugao)[1],
        intensity: $intensity,
        eyebrowType: $brow,
        showBeforeImage: $showBefore
    )
    .padding(28)
    .background(Color.appBackground)
}
