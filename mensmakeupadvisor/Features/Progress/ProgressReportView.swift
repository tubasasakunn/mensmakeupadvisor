import SwiftData
import SwiftUI

// スコアの推移を見せる画面。保存ルック (SavedLook) の totalScore を時系列で
// 集計し、折れ線・サマリ統計・直近の記録一覧で「成長の軌跡」を提示する。
//
// 入口は Archive タブの「スコアの推移」ボタン。戻ると Archive タブへ復帰する。
private enum Layout {
    nonisolated static let labelColumn: CGFloat = 56
}

struct ProgressReportView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \SavedLook.createdAt, order: .forward) private var savedLooks: [SavedLook]

    private var metrics: ProgressMetrics { .make(from: savedLooks) }

    var body: some View {
        ZStack {
            LuxeBackground()

            VStack(spacing: 0) {
                header
                    .padding(.top, Theme.Spacing.md)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        titleSection
                            .padding(.top, Theme.Spacing.xl)
                        HairlineDivider()
                            .padding(.top, Theme.Spacing.xl)

                        if metrics.isEmpty {
                            emptyState
                                .padding(.top, Theme.Spacing.xl)
                        } else {
                            content
                                .padding(.top, Theme.Spacing.xl)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.bottom, Theme.Spacing.huge)
                }
            }
        }
        .aid("progress_view")
    }

    // MARK: - Header

    private var header: some View {
        ScreenHeader(
            variant: .push,
            kicker: "PROGRESS",
            backAccessibilityLabel: "保存一覧に戻る",
            backAccessibilityID: "progress_back_button",
            onBack: { appState.navigation.openHome(tab: .archive) }
        )
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("あなたの軌跡")
                .font(Theme.Typography.Display.s34Bold)
                .italic()
                .foregroundStyle(Color.ivory)
            Text("保存したルックのスコア推移")
                .font(Theme.Typography.UI.subheadline)
                .foregroundStyle(Color.inkSecondary)
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            statRow
            trendCard
            recentList
            reEvaluateButton
        }
    }

    // 最新 / ベスト / 平均 の 3 連サマリ。
    private var statRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            statCell(label: "最新", value: metrics.latest, accent: ScoreGrade.color(for: metrics.latest))
            statCell(label: "ベスト", value: metrics.best, accent: .sulphur)
            statCell(label: "平均", value: metrics.average, accent: .ivory)
        }
        .aid("progress_stat_row")
    }

    private func statCell(label: String, value: Int, accent: Color) -> some View {
        GlassCard(radius: Theme.Radius.md, padding: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(label)
                    .font(Theme.Typography.Data.smallMedium)
                    .kerning(1.5)
                    .foregroundStyle(Theme.Text.secondaryFaded)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(value)")
                        .font(Theme.Typography.Display.s28Light)
                        .italic()
                        .foregroundStyle(accent)
                    Text("pt")
                        .font(Theme.Typography.Data.small)
                        .foregroundStyle(Theme.Text.tertiary)
                }
            }
        }
    }

    // 折れ線チャート + 推移の一言 + 期間。
    private var trendCard: some View {
        GlassCard(radius: Theme.Radius.lg, padding: Theme.Spacing.xl) {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                HStack {
                    Text("スコアの推移")
                        .font(Theme.Typography.Data.mediumMedium)
                        .kerning(1.5)
                        .foregroundStyle(Theme.Text.primaryFaded)
                    Spacer()
                    Text("\(metrics.count) 件")
                        .font(Theme.Typography.Data.small)
                        .kerning(1)
                        .foregroundStyle(Theme.Text.tertiary)
                }

                ScoreTrendChart(points: metrics.points)

                if let from = metrics.points.first?.date, let to = metrics.points.last?.date {
                    HStack {
                        Text(from.formatted(.dateTime.year().month().day()))
                        Spacer()
                        Text(to.formatted(.dateTime.year().month().day()))
                    }
                    .font(Theme.Typography.Data.small)
                    .foregroundStyle(Theme.Text.tertiary)
                }

                HairlineDivider()

                HStack(spacing: 6) {
                    Image(systemName: deltaIcon)
                        .font(Theme.Typography.UI.caption)
                        .foregroundStyle(deltaColor)
                    Text(metrics.deltaCaption)
                        .font(Theme.Typography.UI.subheadlineMedium)
                        .foregroundStyle(Theme.Text.primarySoft)
                }
            }
        }
        .aid("progress_trend_card")
    }

    private var deltaIcon: String {
        switch metrics.delta {
        case 1...:  "arrow.up.right"
        case ..<0:  "arrow.down.right"
        default:    "arrow.right"
        }
    }

    private var deltaColor: Color {
        switch metrics.delta {
        case 1...:  .sulphur
        case ..<0:  .brandPrimary
        default:    Theme.Text.secondary
        }
    }

    // 直近の記録 (新しい順に最大 6 件)。
    private var recentList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("最近の記録")
                .font(Theme.Typography.Data.mediumMedium)
                .kerning(1.5)
                .foregroundStyle(Theme.Text.primaryFaded)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(recentEntries) { point in
                    HStack {
                        Text(point.date.formatted(.dateTime.month().day()))
                            .font(Theme.Typography.Data.s12)
                            .foregroundStyle(Theme.Text.secondary)
                            .frame(width: Layout.labelColumn, alignment: .leading)
                        Text(ScoreGrade.letter(for: point.score))
                            .font(Theme.Typography.UI.s15Heavy)
                            .foregroundStyle(ScoreGrade.color(for: point.score))
                        Spacer()
                        Text("\(point.score)pt")
                            .font(Theme.Typography.Data.s12)
                            .foregroundStyle(Color.ivory)
                    }
                    .overlay(alignment: .bottom) {
                        HairlineDivider().offset(y: 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aid("progress_recent_list")
    }

    // points は昇順なので、末尾から最大 6 件を新しい順に並べ替える。
    private var recentEntries: [ProgressMetrics.Point] {
        Array(metrics.points.suffix(6).reversed())
    }

    private var reEvaluateButton: some View {
        GlassSecondaryButton(
            title: "もう一度撮影して記録する",
            icon: "camera.fill",
            accessibilityID: "progress_reeval_button"
        ) {
            Haptics.soft()
            appState.navigation.openCapture(from: .home)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        GlassCard(radius: Theme.Radius.xl, padding: Theme.Spacing.xxl) {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(Theme.Typography.UI.numeralUltraLight)
                    .foregroundStyle(Theme.Text.secondary)
                Text("まだ推移はありません")
                    .font(Theme.Typography.Display.headlineSemibold)
                    .foregroundStyle(Color.ivory)
                Text("ルックを保存するたびに、その時のスコアが\nここに記録され、成長の軌跡が見えてきます。")
                    .font(Theme.Typography.UI.subheadline)
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)

                GlassPrimaryButton(
                    title: "撮影をはじめる",
                    icon: "camera.fill",
                    accessibilityID: "progress_empty_start_button"
                ) {
                    Haptics.medium()
                    appState.navigation.openCapture(from: .home)
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .frame(maxWidth: .infinity)
        }
        .aid("progress_empty")
    }
}

// MARK: - Preview

@MainActor
private func progressPreviewContainer() -> ModelContainer {
    do {
        let container = try ModelContainer(
            for: SavedLook.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let scores = [56, 62, 60, 68, 71, 78]
        for (i, s) in scores.enumerated() {
            container.mainContext.insert(
                SavedLook(
                    createdAt: .now.addingTimeInterval(Double(-86400 * (scores.count - i) * 4)),
                    totalScore: s,
                    faceShape: "tamago"
                )
            )
        }
        return container
    } catch {
        fatalError("Preview ModelContainer error: \(error)")
    }
}

#Preview("with data") {
    ProgressReportView()
        .environment(AppState())
        .modelContainer(progressPreviewContainer())
}

#Preview("empty") {
    ProgressReportView()
        .environment(AppState())
        .modelContainer(for: SavedLook.self, inMemory: true)
}
