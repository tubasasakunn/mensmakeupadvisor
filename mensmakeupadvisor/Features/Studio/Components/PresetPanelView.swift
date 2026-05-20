import SwiftUI

struct PresetPanelView: View {
    @Environment(AppState.self) private var appState
    let viewModel: StudioViewModel

    // プレビュー表示用の主要カテゴリ。化粧の強弱が一目で分かる 4 軸に絞る
    // (eyeshadow / tearbag / eyeliner はまとめて「目元」として最大値で代表)。
    private let previewAxes: [(label: String, kinds: [MakeupKind])] = [
        ("肌",   [.base]),
        ("光",   [.highlight]),
        ("影",   [.shadow]),
        ("目",   [.eyeshadow, .tearbag, .eyeliner]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("プリセットから選ぶ")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ivory)
                Text("4 つの傾向 — グラフでざっくり比べられます")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSecondary)
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 0), GridItem(.flexible(), spacing: 0)],
                spacing: 0
            ) {
                ForEach(Array(MakeupPreset.all.enumerated()), id: \.element.id) { index, preset in
                    presetCard(preset: preset, index: index)
                }
            }
            .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
        }
    }

    private func presetCard(preset: MakeupPreset, index: Int) -> some View {
        let isActive = appState.activePresetID == preset.id
        return Button {
            viewModel.applyPreset(preset, appState: appState)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .light, design: .serif))
                        .italic()
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                    }
                }

                Text(preset.label)
                    .font(.system(size: 16, weight: .semibold))

                Text(preset.tag)
                    .font(.system(size: 11))
                    .opacity(0.8)

                presetPreviewBars(preset: preset, isActive: isActive)
                    .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isActive ? Color.ivory : Color.clear)
            .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
        }
        .animation(.easeInOut(duration: 0.2), value: appState.activePresetID)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary(for: preset, isActive: isActive))
        .aid("studio_preset_\(preset.id)")
    }

    // 各プリセットの 4 軸を縦バーで示すミニチャート。
    // 縦の長さがその軸の強さに比例する (max ≒ 0.5)。
    private func presetPreviewBars(preset: MakeupPreset, isActive: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<previewAxes.count, id: \.self) { i in
                let axis = previewAxes[i]
                let strength = axisStrength(preset: preset, kinds: axis.kinds)
                VStack(spacing: 4) {
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill((isActive ? Color.appBackground : Color.ivory).opacity(0.15))
                            .frame(width: 8, height: 28)
                        Rectangle()
                            .fill(isActive ? Color.appBackground : Color.ivory)
                            .frame(width: 8, height: max(2, CGFloat(strength) * 56))
                    }
                    Text(axis.label)
                        .font(.system(size: 9))
                        .opacity(0.7)
                }
            }
        }
    }

    private func axisStrength(preset: MakeupPreset, kinds: [MakeupKind]) -> Float {
        kinds.compactMap { preset.intensities[$0] }.max() ?? 0
    }

    private func accessibilitySummary(for preset: MakeupPreset, isActive: Bool) -> String {
        let summary = previewAxes.map { axis in
            let v = Int(axisStrength(preset: preset, kinds: axis.kinds) * 100)
            return "\(axis.label) \(v)"
        }.joined(separator: "、")
        return "\(preset.label)プリセット。\(preset.tag)。\(summary)" + (isActive ? "。選択中" : "")
    }
}

#Preview {
    PresetPanelView(viewModel: StudioViewModel())
        .environment(AppState())
        .padding()
        .background(Color.appBackground)
}
