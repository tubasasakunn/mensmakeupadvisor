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
            Text("FINE TUNE")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)
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
                Text(kind.label.uppercased())
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)
                    .frame(width: 88, alignment: .leading)

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
            .aid("studio_intensity_\(kind.rawValue)")
        }
    }

    private var browTypeRow: some View {
        let options: [(label: String, value: EyebrowApplier.BrowType?)] = [
            ("OFF", nil),
            ("NATURAL", .natural),
            ("STRAIGHT", .straight),
            ("ARCH", .arch),
            ("PARALLEL", .parallel),
            ("CORNER", .corner),
        ]
        return VStack(alignment: .leading, spacing: 8) {
            Text("BROW TYPE")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 6)], spacing: 6) {
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
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .kerning(1.2)
                .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isActive ? Color.ivory : Color.clear)
                .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
        }
        .aid("studio_brow_type_\(aidValue)")
    }
}

#Preview {
    FineTunePanelView()
        .environment(AppState())
        .padding()
        .background(Color.appBackground)
}
