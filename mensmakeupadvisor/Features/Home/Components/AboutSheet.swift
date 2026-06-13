import SwiftUI

// このアプリのことを 1 枚にまとめた静的シート。バージョン・要旨・プライバシー・著作。
// HomeSettingsTab から開かれる。将来項目が増えても本体に戻さず、ここで育てる。
struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        ZStack {
            LuxeBackground(intensity: 0.4)
            VStack(spacing: 0) {
                ScreenHeader(
                    variant: .sheet,
                    kicker: "ABOUT",
                    backAccessibilityLabel: "閉じる",
                    backAccessibilityID: "about_close",
                    onBack: { dismiss() }
                )
                .padding(.top, Theme.Spacing.sm)

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        title
                        HairlineDivider()
                        statement
                        privacy
                        credits
                        version
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("a quiet study in")
                .font(Theme.Typography.Data.baseRegular)
                .kerning(2.5)
                .foregroundStyle(Theme.Text.secondaryFaded)
            Text("The Better Self.")
                .font(Theme.Typography.Display.heroBold)
                .italic()
                .foregroundStyle(Color.ivory)
        }
    }

    private var statement: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionTitle("このアプリのこと")
            Text("紳士の身嗜みを、もう一段階。\n顔の比率と骨格を診て、あなたに合う\nメイクの手順を導く小さなアトリエ。")
                .font(Theme.Typography.UI.callout)
                .foregroundStyle(Theme.Text.primaryFaded)
                .lineSpacing(5)
        }
    }

    private var privacy: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionTitle("プライバシー")
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(Theme.Typography.UI.subheadline)
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .padding(.top, 2)
                Text("撮影画像と診断結果はすべて端末内で処理されます。サーバーへのアップロード・解析の外部送信は一切行いません。")
                    .font(Theme.Typography.UI.callout)
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .lineSpacing(5)
            }
        }
    }

    private var credits: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionTitle("クレジット")
            Text("顔ランドマーク検出に MediaPipe FaceMesh を使用しています。Liquid Glass デザインは iOS 26 SDK の機能を利用しています。")
                .font(Theme.Typography.UI.callout)
                .foregroundStyle(Theme.Text.primaryFaded)
                .lineSpacing(5)
        }
    }

    private var version: some View {
        HStack {
            Text("Version")
                .font(Theme.Typography.Data.base)
                .foregroundStyle(Theme.Text.tertiary)
            Spacer()
            Text("\(appVersion) (\(appBuild))")
                .font(Theme.Typography.Data.base)
                .foregroundStyle(Theme.Text.secondaryFaded)
        }
        .padding(.top, Theme.Spacing.lg)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.Data.mediumMedium)
            .kerning(1.5)
            .foregroundStyle(Theme.Text.primaryFaded)
    }
}

#Preview {
    AboutSheet()
}
