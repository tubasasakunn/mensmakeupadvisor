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
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .kerning(3)
            .foregroundStyle(Theme.Text.secondaryFaded)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("メイクを試す")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
            Text("撮って、診て、塗ってみる。")
                .font(.system(size: 13))
                .foregroundStyle(Color.inkSecondary)
                .kerning(0.5)
        }
    }

    // hero。Glass の白っぽい下敷きを外し、暗色背景を素通しで読ませる。
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            HStack(alignment: .firstTextBaseline) {
                Text("3 STEPS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .kerning(2.5)
                    .foregroundStyle(Theme.Text.secondaryFaded)
                Spacer()
                Text("≈ 90s")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .kerning(1.5)
                    .foregroundStyle(Theme.Text.secondaryFaded)
            }

            Text("自分の顔を撮って、\nメイクを試してみる。")
                .font(.system(size: 22, weight: .bold, design: .serif))
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
                .font(.system(size: 16, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Theme.Text.secondary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.ivory)
        }
    }

    private var heroArrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Theme.Text.secondaryDim)
    }

    private var lastPresetHint: some View {
        HStack {
            Image(systemName: "clock")
                .font(.system(size: 10))
                .foregroundStyle(Theme.Text.tertiary)
            if let result = appState.analysisResult {
                Text("前回の診断: \(result.faceShape.label) · \(result.grade)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Text.tertiary)
            } else {
                Text("初回の撮影です")
                    .font(.system(size: 11))
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
