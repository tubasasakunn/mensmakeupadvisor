import SwiftUI

// Tutorial の本文ブロック内に出す、その step のレイヤー強度を直接いじる
// ためのスライダー部品。値は親 (AppState.intensity[layer]) に直結。
struct TutorialIntensitySlider: View {
    let layer: MakeupLayer
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("INTENSITY")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)

                Text(String(format: "%.0f", value))
                    .font(.system(size: 36, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
            }

            CustomIntensitySlider(value: $value, range: 0...100)
                .aid("tutorial_intensity_slider_\(layer.rawValue)")

            HStack {
                Text("OFF")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("· 50 ·")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("MAX")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
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
