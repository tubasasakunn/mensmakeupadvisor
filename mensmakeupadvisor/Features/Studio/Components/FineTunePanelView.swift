import SwiftUI

struct FineTunePanelView: View {
    @Environment(AppState.self) private var appState

    // 新しい順序 (base → highlight → shadow → eye)。眉はスライダーではなく
    // type picker で操作するためここから外す。
    private let sliderLayers: [MakeupLayer] = [.base, .highlight, .shadow, .eye]

    // 各カテゴリで選べる area name の一覧 (target.json 由来)。アプリ起動時に 1 回読む。
    private let highlightAreaNames: [String] = MeshAreaLibrary.load(category: .highlight).map(\.name)
    private let shadowAreaNames:    [String] = MeshAreaLibrary.load(category: .shadow).map(\.name)
    private let eyeAreaNames:       [String] = ["eyeshadow_base", "eyeshadow_crease", "tear_bag", "lower_outer", "eyeliner"]

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
                        areaChipsSection(
                            title: "HIGHLIGHT AREAS",
                            areas: highlightAreaNames,
                            selected: appState.highlightAreas,
                            toggle: { name in toggle(name, in: &bindable.highlightAreas) },
                            aidPrefix: "studio_highlight_area"
                        )
                    }
                    if layer == .shadow {
                        areaChipsSection(
                            title: "SHADOW AREAS",
                            areas: shadowAreaNames,
                            selected: appState.shadowAreas,
                            toggle: { name in toggle(name, in: &bindable.shadowAreas) },
                            aidPrefix: "studio_shadow_area"
                        )
                    }
                    if layer == .eye {
                        areaChipsSection(
                            title: "EYE AREAS",
                            areas: eyeAreaNames,
                            selected: appState.eyeAreas,
                            toggle: { name in toggle(name, in: &bindable.eyeAreas) },
                            aidPrefix: "studio_eye_area"
                        )
                    }
                }

                browTypeRow(bindable: bindable)
            }
        }
    }

    private func toggle(_ name: String, in set: inout Set<String>) {
        if set.contains(name) {
            set.remove(name)
        } else {
            set.insert(name)
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

    // 複数選択可能な area チップ行
    private func areaChipsSection(title: String,
                                  areas: [String],
                                  selected: Set<String>,
                                  toggle: @escaping (String) -> Void,
                                  aidPrefix: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)

            // 横並び flow layout。SwiftUI の LazyVGrid(.adaptive(min:)) で
            // チップサイズに応じて自動折り返し。
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 6)], spacing: 6) {
                ForEach(areas, id: \.self) { name in
                    let isOn = selected.contains(name)
                    Button {
                        withAnimation(.easeInOut(duration: 0.12)) { toggle(name) }
                    } label: {
                        Text(MakeupAreaLabel.display(name))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .kerning(1.2)
                            .foregroundStyle(isOn ? Color.appBackground : Color.ivory)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(isOn ? Color.ivory : Color.clear)
                            .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
                    }
                    .aid("\(aidPrefix)_\(name)")
                }
            }
        }
        .padding(.top, 4)
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

// MARK: - Studio Slider

struct StudioSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let handleX = fraction * width

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.lineColor)
                    .frame(height: 1)

                Rectangle()
                    .fill(Color.ivory.opacity(0.5))
                    .frame(width: handleX, height: 1)

                Rectangle()
                    .fill(Color.ivory)
                    .frame(width: 6, height: 14)
                    .offset(x: handleX - 3)
            }
            .contentShape(Rectangle().size(CGSize(width: width, height: 44)).offset(y: -22))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let fraction = (drag.location.x / width).clamped(to: 0...1)
                        value = range.lowerBound + fraction * (range.upperBound - range.lowerBound)
                    }
            )
        }
        .frame(height: 14)
    }
}

#Preview {
    FineTunePanelView()
        .environment(AppState())
        .padding()
        .background(Color.appBackground)
}
