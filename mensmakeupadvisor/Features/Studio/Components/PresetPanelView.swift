import SwiftUI

struct PresetPanelView: View {
    @Environment(AppState.self) private var appState
    let viewModel: StudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("プリセットから選ぶ")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ivory)
                Text("タップして仕上がりを比べる")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSecondary)
            }

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
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(isActive ? Color.ivory : Color.clear)
                        .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
                    }
                    .animation(.easeInOut(duration: 0.2), value: appState.activePresetID)
                    .accessibilityLabel("\(preset.label)プリセット。\(preset.tag)" + (isActive ? "。選択中" : ""))
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
