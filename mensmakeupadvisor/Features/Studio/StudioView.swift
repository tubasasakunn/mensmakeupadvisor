import SwiftData
import SwiftUI

struct StudioView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StudioViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 8)

                StudioImagePlate(viewModel: viewModel)
                    .padding(.horizontal, 28)
                    .padding(.top, 12)

                modeSegment
                    .padding(.top, 16)
                    .padding(.horizontal, 28)

                controlPanel
                    .padding(.top, 16)
                    .padding(.horizontal, 28)

                Spacer()

                StudioBottomBar {
                    viewModel.saveLook(appState: appState, modelContext: modelContext)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }

            if viewModel.showSavedNotification {
                StudioSavedToast()
            }
        }
        // 親 identifier が子の Button/Toggle 等に継承されないようにする
        .accessibilityElement(children: .contain)
        .aid("studio_view")
        // composition の変化で task が再起動 → AppState 側で debounce している。
        .task(id: compositionKey) {
            await MainActor.run { appState.requestMakeupRender() }
        }
    }

    // 全化粧単位の強度 + 眉 type を 1 つのキーに集約して task(id:) で監視する。
    private var compositionKey: String {
        let comp = appState.composition
        let parts = MakeupKind.allCases.map {
            "\($0.rawValue):\(Int(comp.intensity(of: $0) * 100))"
        }
        return parts.joined(separator: "|") + "|brow:\(comp.browType?.rawValue ?? "off")"
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            Button {
                appState.navigate(to: .diagnosis)
            } label: {
                Text("← REPORT")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
            }
            .aid("studio_back_button")

            Spacer()

            Text("ATELIER · STUDIO")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.ivory)
                .kerning(2)

            Spacer()

            Button {
                appState.navigate(to: .home)
            } label: {
                Text("HOME →")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
            }
            .aid("studio_header_home_button")
        }
        .padding(.horizontal, 28)
    }

    private var modeSegment: some View {
        HStack(spacing: 0) {
            modeButton(title: "COMPARE", mode: .compare, aid: "studio_compare_button")
            modeButton(title: "FINE TUNE", mode: .fineTune, aid: "studio_finetune_button")
        }
        .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
    }

    private func modeButton(title: String, mode: StudioViewModel.DisplayMode, aid: String) -> some View {
        let isActive = viewModel.displayMode == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.displayMode = mode }
        } label: {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .kerning(1.5)
                .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isActive ? Color.ivory : Color.clear)
        }
        .aid(aid)
        .animation(.easeInOut(duration: 0.2), value: viewModel.displayMode)
    }

    @ViewBuilder
    private var controlPanel: some View {
        switch viewModel.displayMode {
        case .compare:
            PresetPanelView(viewModel: viewModel)
        case .fineTune:
            // FINE TUNE は要素が多い (4 slider + 2 preset 群 + brow picker) ので
            // 高さに収まらないことがある。ScrollView でラップして上下にスワイプ
            // できるようにする。画像プレートが潰れるのを防ぐ。
            ScrollView(.vertical, showsIndicators: false) {
                FineTunePanelView()
                    .padding(.bottom, 8)
            }
        }
    }

}

// MARK: - Preview

#Preview {
    StudioView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
