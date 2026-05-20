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
        GlassPanel(radius: Theme.Radius.lg, padding: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PRESET")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .kerning(2)
                        .foregroundStyle(Theme.Text.secondaryFaded)
                    Text("4 つの傾向から選ぶ")
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.ivory)
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Theme.Spacing.sm),
                        GridItem(.flexible(), spacing: Theme.Spacing.sm)
                    ],
                    spacing: Theme.Spacing.sm
                ) {
                    ForEach(Array(MakeupPreset.all.enumerated()), id: \.element.id) { index, preset in
                        presetCard(preset: preset, index: index)
                    }
                }
            }
        }
    }

    private func presetCard(preset: MakeupPreset, index: Int) -> some View {
        let isActive = appState.activePresetID == preset.id
        return Button {
            guard !isActive else { return }
            Haptics.selection()
            viewModel.applyPreset(preset, appState: appState)
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: 6) {
                    Text(String(format: "%02d", index + 1))
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .opacity(0.7)
                    Spacer()
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                    }
                }

                Text(preset.label)
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .italic()

                Text(preset.tag)
                    .font(.system(size: 11))
                    .opacity(0.75)

                presetPreviewBars(preset: preset, isActive: isActive)
                    .padding(.top, 4)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(isActive ? Color.ivory : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(
                        isActive ? Color.clear : Theme.Line.outlineIvorySoft,
                        lineWidth: 0.5
                    )
            )
        }
        .animation(Theme.Motion.smooth, value: appState.activePresetID)
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
                        .font(.system(size: 11))
                        .opacity(0.75)
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
