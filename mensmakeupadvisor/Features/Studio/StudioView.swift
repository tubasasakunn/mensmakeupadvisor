import SwiftData
import SwiftUI

// 仕上がり確認専用のシンプルな画面。
// プリセット切替や FineTune の調整はもう持たず、Tutorial 工程で組んだ顔を
// Before/After スライダーだけで眺めて確定する。CTA は底に 1 つだけ。
struct StudioView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StudioViewModel()
    @State private var isPreparingShare = false

    var body: some View {
        ZStack {
            LuxeBackground()

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, Theme.Spacing.sm)

                StudioImagePlate(viewModel: viewModel)
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.top, Theme.Spacing.md)

                Spacer(minLength: 0)

                nextButton
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.bottom, Theme.Spacing.xxxl)
            }
        }
        .accessibilityElement(children: .contain)
        .aid("studio_view")
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

    // 戻り先は AppState.studioOrigin に従う。
    // - Diagnosis 経由（新規撮影 or Tutorial 完了）: 診断結果へ
    // - Archive 経由（保存ルックの編集）: ホームへ
    private var backLabel: String {
        appState.studioOrigin == .home ? "ホーム" : "診断結果"
    }

    private var headerBar: some View {
        HStack {
            Button {
                Haptics.soft()
                appState.tryingSavedLook = false
                appState.navigate(to: appState.studioOrigin)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text(backLabel)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Theme.Text.primarySoft)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 7)
                .glassEffect(.clear, in: .capsule)
            }
            .accessibilityLabel("\(backLabel)に戻る")
            .aid("studio_back_button")

            Spacer()

            Text("STUDIO")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .kerning(3)
                .foregroundStyle(Theme.Text.primaryFaded)

            Spacer()

            shareIconButton
        }
        .padding(.horizontal, Theme.Spacing.xxl)
    }

    // 右上の小さな共有アイコン。共有内容は MakeupShareCardView。
    // 試すフローと通常フローで mode を出し分け、ラベルだけ違いを残す。
    private var shareIconButton: some View {
        Button {
            Haptics.soft()
            Task { await shareCurrentLook() }
        } label: {
            Group {
                if isPreparingShare {
                    ProgressView()
                        .tint(Theme.Text.primarySoft)
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Text.primarySoft)
                }
            }
            .frame(width: 30, height: 30)
            .glassEffect(.clear, in: .circle)
        }
        .accessibilityLabel(isPreparingShare ? "共有画像を準備中" : "この仕上がりを共有する")
        .aid("studio_share_button")
        .disabled(isPreparingShare)
    }

    private func shareCurrentLook() async {
        isPreparingShare = true
        defer { isPreparingShare = false }
        let card = MakeupShareCardView(
            renderedImage: appState.renderedImage,
            capturedImage: appState.capturedImage,
            composition: appState.composition,
            result: appState.analysisResult,
            mode: appState.tryingSavedLook ? .tried : .styled
        )
        if let image = ShareHelper.render(card) {
            ShareHelper.present([image])
        }
    }

    // 通常フロー: 保存 → 完了画面 (CompletionView) → ホーム。
    // Try フロー (Archive 経由): 保存せず直接ホームへ。
    // 試すたびに SavedLook が増えるとアーカイブが汚れるので保存しない。
    private var nextButton: some View {
        let isTrying = appState.tryingSavedLook
        return GlassPrimaryButton(
            title: isTrying ? "完了" : "次へ",
            accessibilityID: "studio_next_button"
        ) {
            Haptics.success()
            if !isTrying {
                viewModel.saveLook(appState: appState, modelContext: modelContext)
            }
            appState.tryingSavedLook = false
            appState.navigate(to: isTrying ? .home : .completion)
        }
    }
}

// MARK: - Preview

#Preview {
    StudioView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
