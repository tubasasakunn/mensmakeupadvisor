import SwiftUI

// 直近の顔評価サマリ + 再評価ボタン。analysisResult が nil の場合は
// 「まずは撮影してください」の誘導を出す。
struct HomeReportTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            LuxeBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    kickerLabel
                        .padding(.top, Theme.Spacing.xxxl)
                    titleSection
                        .padding(.top, Theme.Spacing.md)
                    HairlineDivider()
                        .padding(.top, Theme.Spacing.xxl)
                    contentSection
                        .padding(.top, Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.bottom, Theme.Spacing.huge)
            }
        }
        .aid("home_report_tab")
    }

    private var kickerLabel: some View {
        Text("REPORT")
            .font(Theme.Typography.Data.baseMedium)
            .kerning(3)
            .foregroundStyle(Theme.Text.secondaryFaded)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("診断レポート")
                .font(Theme.Typography.Display.heroXLBold)
                .italic()
                .foregroundStyle(Color.ivory)
            Text("あなたの顔の診断結果")
                .font(Theme.Typography.UI.subheadline)
                .foregroundStyle(Color.inkSecondary)
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if let result = appState.analysisResult {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                summaryCard(result: result)
                scorePreviewCard(result: result)
                actionButtons
            }
        } else {
            emptyState
        }
    }

    // 一番上の hero — 顔型・グレード・パーセンタイル
    // 顔型 (卵型 など) ラベルの背景に白っぽい Glass が乗ると読みにくいので
    // LuxeBackground の暗色をそのまま見せる。
    private func summaryCard(result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(result.faceShape.label)
                    .font(Theme.Typography.Display.heroBold)
                    .italic()
                    .foregroundStyle(Color.ivory)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(result.grade)
                        .font(Theme.Typography.Display.numeralXXLLight)
                        .italic()
                        .foregroundStyle(result.gradeColor)
                    Text("\(result.totalScore) pt")
                        .font(Theme.Typography.Data.base)
                        .kerning(1)
                        .foregroundStyle(Theme.Text.secondary)
                }
            }
            Text(result.faceShape.note)
                .font(Theme.Typography.UI.subheadline)
                .foregroundStyle(Theme.Text.primaryFaded)
                .lineSpacing(5)
            HairlineDivider()
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(Theme.Typography.UI.caption)
                    .foregroundStyle(Theme.Text.secondary)
                Text(result.rankPercentile)
                    .font(Theme.Typography.UI.subheadlineMedium)
                    .foregroundStyle(Theme.Text.primarySoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 7 評価指標の表
    private func scorePreviewCard(result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack {
                Text("7 つの評価指標")
                    .font(Theme.Typography.Data.mediumMedium)
                    .kerning(1.5)
                    .foregroundStyle(Theme.Text.primaryFaded)
                Spacer()
                Text("SEVEN")
                    .font(Theme.Typography.Data.small)
                    .kerning(2)
                    .foregroundStyle(Theme.Text.tertiary)
            }
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(result.scores.enumerated()), id: \.element.id) { idx, score in
                    HStack {
                        Text(String(format: "%02d", idx + 1))
                            .font(Theme.Typography.Data.small)
                            .foregroundStyle(Theme.Text.tertiary)
                        Text(score.name)
                            .font(Theme.Typography.UI.calloutMedium)
                            .foregroundStyle(Color.ivory)
                        Spacer()
                        Text(score.grade)
                            .font(Theme.Typography.UI.bodyHeavy)
                            .foregroundStyle(score.gradeColor)
                        Text("\(score.score)pt")
                            .font(Theme.Typography.Data.base)
                            .foregroundStyle(Theme.Text.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                    .overlay(alignment: .bottom) {
                        HairlineDivider().offset(y: 7)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            GlassPrimaryButton(
                title: "詳しいレポートを見る",
                accessibilityID: "home_report_open_button"
            ) {
                // Home 経由の閲覧フロー。戻り先と CTA の出し分けに使う。
                appState.skipDiagnosisOnNextFlow = false
                appState.navigation.openDiagnosis(from: .home)
            }

            GlassSecondaryButton(
                title: "もう一度撮影して評価する",
                icon: "arrow.clockwise",
                accessibilityID: "home_report_reeval_button"
            ) {
                Haptics.soft()
                appState.navigation.openCapture(from: .home)
            }
        }
    }

    private var emptyState: some View {
        GlassCard(radius: Theme.Radius.xl, padding: Theme.Spacing.xxl) {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "face.dashed")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundStyle(Theme.Text.secondary)
                Text("まだ診断結果はありません")
                    .font(Theme.Typography.Display.headlineSemibold)
                    .foregroundStyle(Color.ivory)
                Text("顔写真を撮ると、ここに 7 つの指標で\nスコアが表示されます。")
                    .font(Theme.Typography.UI.subheadline)
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                GlassPrimaryButton(
                    title: "撮影をはじめる",
                    icon: "camera.fill",
                    accessibilityID: "home_report_start_button"
                ) {
                    Haptics.medium()
                    appState.navigation.openCapture(from: .home)
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    HomeReportTab()
        .environment(AppState())
}
