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
    // 「次へ」を押したあと、tryingSavedLook == false なら名前付けシートを挟む。
    @State private var showSaveSheet = false
    @State private var showArrangeSheet = false

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

                VStack(spacing: Theme.Spacing.md) {
                    HStack(spacing: Theme.Spacing.md) {
                        mirrorButton
                        arrangeButton
                    }
                    nextButton
                }
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.bottom, Theme.Spacing.xxxl)
            }
        }
        .accessibilityElement(children: .contain)
        .aid("studio_view")
        .task(id: compositionKey) {
            await MainActor.run { appState.requestMakeupRender() }
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveTitleSheet(
                onSave: { title, memo in
                    viewModel.saveLook(
                        appState: appState,
                        modelContext: modelContext,
                        title: title,
                        memo: memo
                    )
                    showSaveSheet = false
                    appState.tryingSavedLook = false
                    appState.navigate(to: .completion)
                },
                onCancel: { showSaveSheet = false }
            )
            .presentationBackground(Theme.Ambient.backdrop)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showArrangeSheet) {
            StudioArrangeSheet()
                .environment(appState)
                .presentationBackground(Theme.Ambient.backdrop)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
    private var backAccessibilityLabel: String {
        appState.studioOrigin == .home ? "ホームに戻る" : "診断結果に戻る"
    }

    private var headerBar: some View {
        ScreenHeader(
            variant: .push,
            kicker: "STUDIO",
            backAccessibilityLabel: backAccessibilityLabel,
            backAccessibilityID: "studio_back_button",
            onBack: {
                appState.tryingSavedLook = false
                appState.navigate(to: appState.studioOrigin)
            },
            trailing: { shareIconButton }
        )
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
                        .font(Theme.Typography.UI.calloutSemibold)
                        .foregroundStyle(Theme.Text.primarySoft)
                }
            }
            .frame(width: Theme.Size.Control.circleSmall, height: Theme.Size.Control.circleSmall)
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

    // 鏡モード: フロントカメラの鏡像にガイドを重ね、実際に塗りながら確認する。
    // 戻り先は Studio (この画面)。
    private var mirrorButton: some View {
        GlassSecondaryButton(
            title: "鏡モード",
            icon: "camera.viewfinder",
            accessibilityID: "studio_mirror_button"
        ) {
            Haptics.soft()
            appState.navigation.openMirror(back: .studio)
        }
    }

    // アレンジ: プリセット比較・カラー調整をまとめた任意の微調整シート。
    private var arrangeButton: some View {
        GlassSecondaryButton(
            title: "アレンジ",
            icon: "slider.horizontal.3",
            accessibilityID: "studio_arrange_button"
        ) {
            Haptics.soft()
            showArrangeSheet = true
        }
    }

    // 通常フロー: 「次へ」→ 名前付けシート → 保存 → 完了画面 → ホーム。
    // Try フロー (Archive 経由): 保存せず直接ホームへ。
    // 試すたびに SavedLook が増えるとアーカイブが汚れるので保存しない。
    private var nextButton: some View {
        let isTrying = appState.tryingSavedLook
        return GlassPrimaryButton(
            title: isTrying ? "完了" : "次へ",
            accessibilityID: "studio_next_button"
        ) {
            Haptics.medium()
            if isTrying {
                appState.tryingSavedLook = false
                appState.navigate(to: .home)
            } else {
                showSaveSheet = true
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
