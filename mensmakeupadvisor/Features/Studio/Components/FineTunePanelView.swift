import SwiftUI

// FINE TUNE: 化粧単位ごとの強度スライダー + 眉タイプ選択。
// 各スライダーはその化粧単位の全メッシュに一律の強度を適用する。
struct FineTunePanelView: View {
    @Environment(AppState.self) private var appState

    private let sliderKinds: [MakeupKind] = [
        .base, .highlight, .shadow, .eyeshadow, .tearbag, .eyeliner,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("細かく調整する")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ivory)
                Text("0 で何もしない、50 が標準、100 で最大")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSecondary)
            }
            .padding(.bottom, 16)

            VStack(spacing: 20) {
                ForEach(sliderKinds, id: \.self) { kind in
                    kindSliderRow(kind)
                }
                browTypeRow
            }
        }
    }

    private func kindSliderRow(_ kind: MakeupKind) -> some View {
        let value = Double(appState.composition.intensity(of: kind)) * 100

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline) {
                Text(kind.labelJP)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.ivory)
                    .frame(width: 100, alignment: .leading)

                Spacer()

                Text(String(format: "%.0f", value))
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
                    .frame(width: 36, alignment: .trailing)
            }

            StudioSlider(
                value: Binding(
                    get: { Double(appState.composition.intensity(of: kind)) * 100 },
                    set: { appState.composition.setIntensity(Float($0 / 100), for: kind) }
                ),
                range: 0...100
            )
            .accessibilityLabel("\(kind.labelJP)の強さ")
            .accessibilityValue("\(Int(value))")
            .aid("studio_intensity_\(kind.rawValue)")
        }
    }

    private var browTypeRow: some View {
        let options: [(label: String, value: EyebrowApplier.BrowType?)] = [
            ("なし", nil),
            ("ナチュラル", .natural),
            ("ストレート", .straight),
            ("アーチ", .arch),
            ("平行", .parallel),
            ("角度あり", .corner),
        ]
        return VStack(alignment: .leading, spacing: 8) {
            Text("眉のかたち")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.ivory)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 6)], spacing: 6) {
                ForEach(0..<options.count, id: \.self) { i in
                    browTypeButton(options[i])
                }
            }
        }
        .padding(.top, 4)
    }

    private func browTypeButton(_ entry: (label: String, value: EyebrowApplier.BrowType?)) -> some View {
        let isActive = (entry.value == appState.composition.browType)
        let aidValue = entry.value?.rawValue ?? "off"
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.composition.setBrowType(entry.value)
            }
        } label: {
            Text(entry.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isActive ? Color.ivory : Color.clear)
                .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
        }
        .accessibilityLabel("眉のかたち\(entry.label)" + (isActive ? "。選択中" : ""))
        .aid("studio_brow_type_\(aidValue)")
    }
}

#Preview {
    FineTunePanelView()
        .environment(AppState())
        .padding()
        .background(Color.appBackground)
}
