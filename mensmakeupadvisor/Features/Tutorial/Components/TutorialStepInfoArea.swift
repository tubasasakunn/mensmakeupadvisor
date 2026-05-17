import SwiftUI

// Tutorial の各ステップの本文エリア。
// オンボーディングでは「化粧反映の選択は不要」のため、スライダー / チップ /
// 眉 picker などの選択 UI は持たない。タイトル + リード + パーソナライズ説明文
// と、長押しで before を見るボタンのみ。
struct TutorialStepInfoArea: View {
    let currentStep: TutorialStep
    @Binding var showBeforeImage: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.vertical, 14)

            Text(currentStep.oneLiner)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory.opacity(0.92))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            Text(currentStep.explanation)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            beforeButton
                .padding(.top, 18)
        }
    }

    private var beforeButton: some View {
        Button {
            // タップでもトグル可能
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
    @Previewable @State var showBefore = false
    return TutorialStepInfoArea(
        currentStep: TutorialStep.sequence(for: .marugao)[1],
        showBeforeImage: $showBefore
    )
    .padding(28)
    .background(Color.appBackground)
}
