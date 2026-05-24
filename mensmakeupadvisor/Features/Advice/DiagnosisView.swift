import SwiftUI
import UIKit

struct DiagnosisView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            LuxeBackground()

            VStack(spacing: 0) {
                navigationBar
                    .padding(.top, Theme.Spacing.md)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        reportHeader
                            .padding(.top, Theme.Spacing.xl)
                            .padding(.horizontal, Theme.Spacing.xl)

                        titleBlock
                            .padding(.top, Theme.Spacing.md)
                            .padding(.horizontal, Theme.Spacing.xl)

                        captionLine
                            .padding(.top, Theme.Spacing.sm)
                            .padding(.horizontal, Theme.Spacing.xl)

                        HairlineDivider()
                            .padding(.top, Theme.Spacing.xl)
                            .padding(.horizontal, Theme.Spacing.xl)

                        // 背景は LuxeBackground のままで読ませる (Glass の白っぽさが
                        // 顔型ラベルや本文と干渉していたため、コンテンツのみ配置)。
                        DiagnosisHeroSection(result: result)
                            .padding(.top, Theme.Spacing.xl)
                            .padding(.horizontal, Theme.Spacing.xl)

                        // スコアを見た直後の「シェアしたい」瞬間に配置
                        DiagnosisSharePrompt(result: result)
                            .padding(.top, Theme.Spacing.xl)
                            .padding(.horizontal, Theme.Spacing.xl)

                        DiagnosisFaceMeshPlate(capturedImage: appState.capturedImage, result: result)
                            .padding(.top, Theme.Spacing.xl)
                            .padding(.horizontal, Theme.Spacing.xl)

                        DiagnosisProportionPlate(capturedImage: appState.capturedImage, result: result)
                            .padding(.top, Theme.Spacing.lg)
                            .padding(.horizontal, Theme.Spacing.xl)

                        HairlineDivider()
                            .padding(.top, Theme.Spacing.xl)
                            .padding(.horizontal, Theme.Spacing.xl)

                        DiagnosisScoreListSection(result: result, capturedImage: appState.capturedImage)
                            .padding(.top, Theme.Spacing.xs)
                            .padding(.horizontal, Theme.Spacing.xl)

                        // Home 経由の閲覧フロー（再訪）は静かに眺める画面なので、
                        // 強い CTA を置かない。新規解析フローからのみ次工程へ送り出す。
                        if appState.diagnosisOrigin != .home {
                            bottomButtons
                                .padding(.top, Theme.Spacing.xxxl)
                                .padding(.horizontal, Theme.Spacing.xl)
                                .padding(.bottom, Theme.Spacing.huge)
                        } else {
                            Color.clear.frame(height: Theme.Spacing.huge)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        // 親に付けた identifier を子の Button (BACK / BEGIN / SKIP) に継承させない。
        .accessibilityElement(children: .contain)
        .aid("diagnosis_view")
    }

    private var result: AnalysisResult {
        appState.analysisResult ?? .mock
    }

    // MARK: - Navigation

    // 戻り先は diagnosisOrigin に従う。
    // - 新規解析（Analyzing 経由）: .capture へ
    // - Home Report 経由の再閲覧: .home へ
    private var backDestination: AppScreen { appState.diagnosisOrigin }
    private var backAccessibilityLabel: String {
        switch backDestination {
        case .home: "ホームに戻る"
        case .capture: "撮影画面に戻る"
        default: "戻る"
        }
    }

    private var navigationBar: some View {
        ScreenHeader(
            variant: .push,
            kicker: "RESULT",
            backAccessibilityLabel: backAccessibilityLabel,
            backAccessibilityID: "diagnosis_back_button",
            onBack: { appState.navigate(to: backDestination) }
        )
    }

    // MARK: - Header

    private var reportHeader: some View {
        Text("CHAPTER 07 · RESULT")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Theme.Text.secondaryFaded)
            .kerning(2.8)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("step two.")
                .font(.system(size: 40, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Theme.Text.primaryFaded)

            Text("診断結果.")
                .font(.system(size: 46, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
        }
    }

    private var captionLine: some View {
        Text("— a study of seven proportions —")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Theme.Text.secondaryFaded)
            .kerning(1.8)
    }

    // MARK: - Bottom Buttons

    // タイトル＋サブタイトルを 1 つのボタン内に収める専用 CTA。
    // 旧 UI ではサブタイトルがボタンの外に置かれ、視覚的に分離していて
    // 「これ何の説明？」になっていた。1 つの tap area で読ませる。
    private func ctaWithSubtitle(
        title: String,
        subtitle: String,
        icon: String?,
        isProminent: Bool,
        accessibilityID: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.ivory)
                        .frame(width: 24)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: isProminent ? .semibold : .medium))
                        .foregroundStyle(isProminent ? Color.ivory : Theme.Text.primarySoft)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(isProminent ? Theme.Text.primaryFaded : Theme.Text.secondaryFaded)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isProminent ? Color.ivory.opacity(0.85) : Theme.Text.primaryFaded)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .modifier(GlassPrimaryButtonSurface(isProminent: isProminent))
        }
        .buttonStyle(GlassPressedButtonStyle())
        .accessibilityLabel("\(title)。\(subtitle)")
        .aid(accessibilityID)
    }

    private var bottomButtons: some View {
        let isSkipFlow = appState.skipTutorialOnNextFlow
        return VStack(spacing: Theme.Spacing.md) {
            ctaWithSubtitle(
                title: isSkipFlow ? "スタジオを開く" : "メイクを試してみる",
                subtitle: isSkipFlow ? "プリセットや細かい調整ができます" : "5ステップのガイドに沿って進めます",
                icon: isSkipFlow ? "paintbrush.pointed.fill" : "wand.and.stars",
                isProminent: true,
                accessibilityID: "diagnosis_begin_button"
            ) {
                Haptics.medium()
                appState.studioOrigin = .diagnosis
                if isSkipFlow {
                    appState.skipTutorialOnNextFlow = false
                    appState.navigate(to: .studio)
                } else {
                    appState.navigate(to: .tutorial)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @MainActor func makeState() -> AppState {
        let state = AppState()
        state.analysisResult = .mock
        let r = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
        state.capturedImage = r.image { ctx in
            Theme.UIKitColor.previewCanvas.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
        }
        return state
    }
    return DiagnosisView()
        .environment(makeState())
}
