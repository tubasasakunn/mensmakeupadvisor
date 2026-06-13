import SwiftUI

// Tutorial の本文ブロック内に出す、その step のレイヤー強度を直接いじる
// ためのスライダー部品。値は親 (AppState.intensity[layer]) に直結。
struct TutorialIntensitySlider: View {
    let layer: MakeupLayer
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("強さ")
                    .font(Theme.Typography.UI.calloutMedium)
                    .foregroundStyle(Color.ivory)

                Spacer()

                Text(String(format: "%.0f", value))
                    .font(Theme.Typography.Display.heroLLight)
                    .italic()
                    .foregroundStyle(Color.ivory)
            }

            HairlineSlider(value: $value, range: 0...100, style: .tutorial)
                .accessibilityLabel("\(layer.labelJP)の強さ")
                .accessibilityValue("\(Int(value))")
                .aid("tutorial_intensity_slider_\(layer.rawValue)")

            HStack {
                Text("なし")
                    .font(Theme.Typography.UI.footnote)
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("ふつう")
                    .font(Theme.Typography.UI.footnote)
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("最大")
                    .font(Theme.Typography.UI.footnote)
                    .foregroundStyle(Color.inkSecondary)
            }
        }
    }
}

#Preview {
    @Previewable @State var v: Double = 35
    return TutorialIntensitySlider(layer: .highlight, value: $v)
        .padding()
        .background(Color.appBackground)
}
