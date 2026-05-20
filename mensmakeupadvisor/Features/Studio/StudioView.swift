import SwiftData
import SwiftUI

struct StudioView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StudioViewModel()
    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            LuxeBackground()

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, Theme.Spacing.sm)

                StudioImagePlate(viewModel: viewModel)
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.top, Theme.Spacing.md)

                modeRow
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.horizontal, Theme.Spacing.xxl)

                controlPanel
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.horizontal, Theme.Spacing.xxl)

                Spacer()

                StudioBottomBar {
                    viewModel.saveLook(appState: appState, modelContext: modelContext)
                }
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.bottom, Theme.Spacing.xxxl)
            }

            if viewModel.showSavedNotification {
                StudioSavedToast(
                    onGoHome: {
                        viewModel.dismissSavedNotification()
                        appState.navigate(to: .home)
                    },
                    onKeepEditing: {
                        viewModel.dismissSavedNotification()
                    }
                )
            }
        }
        .confirmationDialog(
            "メイクを全部リセットしますか？",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("リセットする", role: .destructive) {
                viewModel.resetAll(appState: appState)
            }
            Button("やめる", role: .cancel) {}
        } message: {
            Text("すべての強さを 0 に、眉の選択を解除します。")
        }
        .accessibilityElement(children: .contain)
        .aid("studio_view")
        .task(id: compositionKey) {
            await MainActor.run { appState.requestMakeupRender() }
        }
    }

    private var hasAnyIntensity: Bool {
        viewModel.hasAnyIntensity(appState.composition)
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
            backChip(
                label: "診断結果",
                aid: "studio_back_button",
                accessibilityLabel: "診断結果に戻る"
            ) {
                appState.navigate(to: .diagnosis)
            }

            Spacer()

            Text("STUDIO")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .kerning(3)
                .foregroundStyle(Theme.Text.primaryFaded)

            Spacer()

            backChip(
                label: "ホーム",
                aid: "studio_header_home_button",
                accessibilityLabel: "ホームに戻る",
                icon: "house.fill",
                trailing: true
            ) {
                appState.navigate(to: .home)
            }
        }
        .padding(.horizontal, Theme.Spacing.xxl)
    }

    // Header の戻る/ホームチップ。clear glass + ivory outline。
    private func backChip(
        label: String,
        aid: String,
        accessibilityLabel: String,
        icon: String = "chevron.left",
        trailing: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if !trailing {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                if trailing {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .foregroundStyle(Theme.Text.primarySoft)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 7)
            .glassEffect(.clear, in: .capsule)
        }
        .accessibilityLabel(accessibilityLabel)
        .aid(aid)
    }

    private var modeRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            modeSegment
            resetButton
        }
    }

    private var modeSegment: some View {
        HStack(spacing: 0) {
            modeButton(
                title: "比べる",
                subtitle: "Before / After",
                mode: .compare,
                aid: "studio_compare_button"
            )
            modeButton(
                title: "細かく調整",
                subtitle: "色味と強さ",
                mode: .fineTune,
                aid: "studio_finetune_button"
            )
        }
        .glassEffect(.regular, in: .capsule)
    }

    private var resetButton: some View {
        Button {
            showResetConfirmation = true
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .regular))
                Text("リセット")
                    .font(.system(size: 11, weight: .regular))
            }
            .foregroundStyle(hasAnyIntensity ? Color.ivory : Theme.Text.tertiary)
            .frame(width: 56, height: 56)
        }
        .glassEffect(.regular, in: .circle)
        .disabled(!hasAnyIntensity)
        .accessibilityLabel("メイクをリセット")
        .aid("studio_reset_button")
    }

    private func modeButton(title: String, subtitle: String, mode: StudioViewModel.DisplayMode, aid: String) -> some View {
        let isActive = viewModel.displayMode == mode
        return Button {
            withAnimation(Theme.Motion.spring) { viewModel.displayMode = mode }
        } label: {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .kerning(1)
                    .opacity(0.7)
            }
            .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isActive ? Color.ivory : Color.clear)
                    .padding(4)
            )
        }
        .accessibilityLabel("\(title)モード。\(subtitle)")
        .aid(aid)
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
                    .padding(.bottom, Theme.Spacing.sm)
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
