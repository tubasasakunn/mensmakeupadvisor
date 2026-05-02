import SwiftUI

struct PresetPanelView: View {
    @Environment(AppState.self) private var appState
    let viewModel: StudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("EDITOR'S PRESETS")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 0), GridItem(.flexible(), spacing: 0)],
                spacing: 0
            ) {
                ForEach(Array(MakeupPreset.all.enumerated()), id: \.element.id) { index, preset in
                    let isActive = appState.activePresetID == preset.id

                    Button {
                        viewModel.applyPreset(preset, appState: appState)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("n°.\(String(format: "%02d", index + 1))")
                                .font(.system(size: 11, weight: .light, design: .serif))
                                .italic()

                            Text(preset.label)
                                .font(.system(size: 16, weight: .semibold))

                            Text(preset.tag)
                                .font(.system(.caption2, design: .monospaced))
                                .kerning(1)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(isActive ? Color.ivory : Color.clear)
                        .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
                    }
                    .animation(.easeInOut(duration: 0.2), value: appState.activePresetID)
                    .aid("studio_preset_\(preset.id)")
                }
            }
            .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
        }
    }
}

#Preview {
    PresetPanelView(viewModel: StudioViewModel())
        .environment(AppState())
        .padding()
        .background(Color.appBackground)
}
