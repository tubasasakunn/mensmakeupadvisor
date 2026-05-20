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
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.ivory)

                Spacer()

                Text(String(format: "%.0f", value))
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
            }

            CustomIntensitySlider(value: $value, range: 0...100)
                .accessibilityLabel("\(layer.labelJP)の強さ")
                .accessibilityValue("\(Int(value))")
                .aid("tutorial_intensity_slider_\(layer.rawValue)")

            HStack {
                Text("なし")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("ふつう")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("最大")
                    .font(.system(size: 11))
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
