import SwiftUI

// 化粧作成タブ。タップで撮影 → 分析 → Studio (Tutorial スキップ) のフローへ。
struct HomeCreateTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            LuxeBackground()

            VStack(alignment: .leading, spacing: 0) {
                kickerLabel
                    .padding(.top, Theme.Spacing.xxxl)
                titleSection
                    .padding(.top, Theme.Spacing.md)
                HairlineDivider()
                    .padding(.top, Theme.Spacing.xxl)

                Spacer()

                heroCard
                    .padding(.vertical, Theme.Spacing.xxxl)

                Spacer()

                GlassPrimaryButton(
                    title: "カメラで撮影する",
                    icon: "camera.fill",
                    accessibilityID: "home_create_camera_button"
                ) {
                    Haptics.medium()
                    // Create フローは「撮ってすぐ各化粧工程を試す」体験。
                    // 撮影後 Diagnosis を飛ばし、Tutorial に直行する。
                    appState.skipDiagnosisOnNextFlow = true
                    appState.navigation.openCapture(from: .home)
                }

                lastPresetHint
                    .padding(.top, Theme.Spacing.lg)
            }
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.bottom, Theme.Spacing.huge)
        }
        .aid("home_create_tab")
    }

    private var kickerLabel: some View {
        Text("CREATE")
            .font(Theme.Typography.Data.baseMedium)
            .kerning(3)
            .foregroundStyle(Theme.Text.secondaryFaded)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("メイクを試す")
                .font(Theme.Typography.Display.heroXLBold)
                .italic()
                .foregroundStyle(Color.ivory)
            Text("撮って、診て、塗ってみる。")
                .font(Theme.Typography.UI.callout)
                .foregroundStyle(Color.inkSecondary)
                .kerning(0.5)
        }
    }

    // hero。Glass の白っぽい下敷きを外し、暗色背景を素通しで読ませる。
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            HStack(alignment: .firstTextBaseline) {
                Text("3 STEPS")
                    .font(Theme.Typography.Data.smallMedium)
                    .kerning(2.5)
                    .foregroundStyle(Theme.Text.secondaryFaded)
                Spacer()
                Text("≈ 90s")
                    .font(Theme.Typography.Data.smallRegular)
                    .kerning(1.5)
                    .foregroundStyle(Theme.Text.secondaryFaded)
            }

            Text("自分の顔を撮って、\nメイクを試してみる。")
                .font(Theme.Typography.Display.titleBold)
                .foregroundStyle(Color.ivory)
                .lineSpacing(6)

            HairlineDivider()

            HStack(spacing: Theme.Spacing.sm) {
                heroStep(number: "01", label: "撮影")
                heroArrow
                heroStep(number: "02", label: "診断")
                heroArrow
                heroStep(number: "03", label: "メイク")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func heroStep(number: String, label: String) -> some View {
        HStack(spacing: 6) {
            Text(number)
                .font(Theme.Typography.Display.subheadLight)
                .italic()
                .foregroundStyle(Theme.Text.secondary)
            Text(label)
                .font(Theme.Typography.UI.subheadlineMedium)
                .foregroundStyle(Color.ivory)
        }
    }

    private var heroArrow: some View {
        Image(systemName: "chevron.right")
            .font(Theme.Typography.UI.captionMedium)
            .foregroundStyle(Theme.Text.secondaryDim)
    }

    private var lastPresetHint: some View {
        HStack {
            Image(systemName: "clock")
                .font(Theme.Typography.UI.caption)
                .foregroundStyle(Theme.Text.tertiary)
            if let result = appState.analysisResult {
                Text("前回の診断: \(result.faceShape.label) · \(result.grade)")
                    .font(Theme.Typography.UI.footnote)
                    .foregroundStyle(Theme.Text.tertiary)
            } else {
                Text("初回の撮影です")
                    .font(Theme.Typography.UI.footnote)
                    .foregroundStyle(Theme.Text.tertiary)
            }
            Spacer()
        }
    }
}

#Preview {
    HomeCreateTab()
        .environment(AppState())
}
