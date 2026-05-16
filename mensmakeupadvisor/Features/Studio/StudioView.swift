import SwiftData
import SwiftUI

struct StudioView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StudioViewModel()
    @State private var isRenderingShare = false

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

                bottomActions
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
            }

            if viewModel.showSavedNotification {
                savedNotification
            }
        }
        // 親 identifier が子の Button/Toggle 等に継承されないようにする
        .accessibilityElement(children: .contain)
        .aid("studio_view")
        // makeup_claude の MakeupRenderer に強度変更を流す。
        // intensity の値変化で task が再起動 → AppState 側で debounce している。
        .task(id: intensityKey) {
            await MainActor.run { appState.requestMakeupRender() }
        }
    }

    // intensity の各値を 1 つの Hashable キーに集約して task(id:) で監視する
    private var intensityKey: String {
        let i = appState.intensity
        return "\(Int(i.base))-\(Int(i.highlight))-\(Int(i.shadow))-\(Int(i.eye))-\(Int(i.eyebrow))"
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
                appState.navigate(to: .archive)
            } label: {
                Text("SAVED →")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
            }
            .aid("studio_header_saved_button")
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
            FineTunePanelView()
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 10) {
            archiveButton
            shareButton.frame(width: 52)
        }
    }

    private var archiveButton: some View {
        Button {
            viewModel.saveLook(appState: appState, modelContext: modelContext)
        } label: {
            HStack(spacing: 8) {
                Text("♥")
                    .font(.system(size: 14))
                Text("ARCHIVE THIS LOOK")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .kerning(2)
            }
            .foregroundStyle(Color.ivory)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                Rectangle().stroke(Color.lineStrong, lineWidth: 1)
            )
        }
        .aid("studio_save_button")
    }

    private var shareButton: some View {
        Button {
            Task { await shareCurrentLook() }
        } label: {
            Group {
                if isRenderingShare {
                    ProgressView()
                        .tint(Color.inkSecondary)
                        .scaleEffect(0.7)
                } else {
                    Text("↑")
                        .font(.system(size: 18, weight: .light, design: .monospaced))
                        .foregroundStyle(Color.ivory)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(Rectangle().stroke(Color.lineStrong, lineWidth: 1))
        }
        .aid("studio_share_button")
        .disabled(isRenderingShare)
    }

    private func shareCurrentLook() async {
        guard let result = appState.analysisResult else { return }
        isRenderingShare = true
        defer { isRenderingShare = false }
        let card = DiagnosisShareCardView(result: result)
        if let image = ShareHelper.render(card) {
            ShareHelper.present([image])
        }
    }

    private var savedNotification: some View {
        VStack {
            Spacer()
            Text("✓ LOOK ARCHIVED")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.appBackground)
                .kerning(2)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.ivory)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 100)
        }
        .aid("studio_saved_notification")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Preview

#Preview {
    StudioView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
