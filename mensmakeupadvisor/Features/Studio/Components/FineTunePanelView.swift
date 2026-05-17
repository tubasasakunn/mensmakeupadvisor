import SwiftUI

struct FineTunePanelView: View {
    @Environment(AppState.self) private var appState

    private let sliderLayers: [MakeupLayer] = [.base, .highlight, .shadow, .eye]

    var body: some View {
        @Bindable var bindable = appState

        return VStack(alignment: .leading, spacing: 0) {
            Text("FINE TUNE")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)
                .padding(.bottom, 16)

            VStack(spacing: 20) {
                ForEach(sliderLayers, id: \.self) { layer in
                    layerSliderRow(layer)
                    if layer == .highlight {
                        MakeupAreaChipsSection(
                            title: "HIGHLIGHT AREAS",
                            layer: .highlight,
                            selected: $bindable.highlightAreas,
                            aidPrefix: "studio_highlight_area"
                        )
                        .padding(.top, 4)
                    }
                    if layer == .shadow {
                        MakeupAreaChipsSection(
                            title: "SHADOW AREAS",
                            layer: .shadow,
                            selected: $bindable.shadowAreas,
                            aidPrefix: "studio_shadow_area"
                        )
                        .padding(.top, 4)
                    }
                    if layer == .eye {
                        MakeupAreaChipsSection(
                            title: "EYE AREAS",
                            layer: .eye,
                            selected: $bindable.eyeAreas,
                            aidPrefix: "studio_eye_area"
                        )
                        .padding(.top, 4)
                    }
                }

                browTypeRow(bindable: bindable)
            }
        }
    }

    private func layerSliderRow(_ layer: MakeupLayer) -> some View {
        let value = appState.intensity[layer]

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline) {
                Text(layer.label.uppercased())
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)
                    .frame(width: 70, alignment: .leading)

                Spacer()

                Text(String(format: "%.0f", value))
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
                    .frame(width: 36, alignment: .trailing)
            }

            StudioSlider(
                value: Binding(
                    get: { appState.intensity[layer] },
                    set: { appState.intensity[layer] = $0 }
                ),
                range: 0...100
            )
            .aid("studio_intensity_\(layer.rawValue)")
        }
    }

    private func browTypeRow(bindable: AppState) -> some View {
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
                    let entry = options[i]
                    browTypeButton(entry: entry,
                                   current: appState.eyebrowType,
                                   select: { bindable.eyebrowType = $0 })
                }
            }
        }
        .padding(.top, 4)
    }

    private func browTypeButton(entry: (label: String, value: EyebrowApplier.BrowType?),
                                current: EyebrowApplier.BrowType?,
                                select: @escaping (EyebrowApplier.BrowType?) -> Void) -> some View {
        let isActive = (entry.value == current)
        let aidValue = entry.value?.rawValue ?? "off"
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { select(entry.value) }
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
