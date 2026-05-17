import SwiftUI

struct FineTunePanelView: View {
    @Environment(AppState.self) private var appState

    // 新しい順序 (base → highlight → shadow → eye)。眉はスライダーではなく
    // type picker で操作するためここから外す。
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
                        presetRow(
                            title: "HIGHLIGHT TARGET",
                            options: HighlightPreset.allCases,
                            current: appState.highlightPreset,
                            select: { bindable.highlightPreset = $0 },
                            aidPrefix: "studio_highlight_preset"
                        )
                    }
                    if layer == .shadow {
                        presetRow(
                            title: "SHADOW TARGET",
                            options: ShadowPreset.allCases,
                            current: appState.shadowPreset,
                            select: { bindable.shadowPreset = $0 },
                            aidPrefix: "studio_shadow_preset"
                        )
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

    private func presetRow<P: Identifiable & CaseIterable & Hashable>(
        title: String,
        options: P.AllCases,
        current: P,
        select: @escaping (P) -> Void,
        aidPrefix: String
    ) -> some View where P.AllCases: RandomAccessCollection, P: PresetLabelable {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)

            // 横スクロール対応で 3-4 個の選択肢を並べる
            HStack(spacing: 6) {
                ForEach(options) { option in
                    let isActive = (option == current)
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { select(option) }
                    } label: {
                        Text(option.presetLabel)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .kerning(1.2)
                            .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(isActive ? Color.ivory : Color.clear)
                            .overlay(
                                Rectangle().stroke(Color.lineColor, lineWidth: 1)
                            )
                    }
                    .aid("\(aidPrefix)_\(String(describing: option.id))")
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

            // 2 段 (横 3 個) で並べる
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        let entry = options[i]
                        browTypeButton(entry: entry,
                                       current: appState.eyebrowType,
                                       select: { bindable.eyebrowType = $0 })
                    }
                }
                HStack(spacing: 6) {
                    ForEach(3..<6, id: \.self) { i in
                        let entry = options[i]
                        browTypeButton(entry: entry,
                                       current: appState.eyebrowType,
                                       select: { bindable.eyebrowType = $0 })
                    }
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

// preset enum 共通の表示文字列プロトコル
protocol PresetLabelable {
    var presetLabel: String { get }
}
extension HighlightPreset: PresetLabelable { var presetLabel: String { label } }
extension ShadowPreset: PresetLabelable { var presetLabel: String { label } }

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
