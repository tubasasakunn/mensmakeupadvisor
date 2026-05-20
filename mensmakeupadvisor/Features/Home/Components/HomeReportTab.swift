import SwiftUI

// 直近の顔評価サマリ + 再評価ボタン。analysisResult が nil の場合は
// 「まずは撮影してください」の誘導を出す。
struct HomeReportTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.top, 32)
                    titleSection
                        .padding(.top, 12)
                    HairlineDivider()
                        .padding(.top, 24)
                    contentSection
                        .padding(.top, 28)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 80)
            }
        }
        .aid("home_report_tab")
    }

    private var headerSection: some View {
        Text("あなたの顔の診断結果")
            .font(.system(size: 12))
            .foregroundStyle(Color.inkSecondary)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("診断レポート")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.ivory)
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if let result = appState.analysisResult {
            VStack(alignment: .leading, spacing: 24) {
                summaryCard(result: result)
                scorePreviewList(result: result)
                actionButtons
            }
        } else {
            emptyState
        }
    }

    private func summaryCard(result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(result.faceShape.label)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
                Spacer()
                Text(result.grade)
                    .font(.system(size: 42, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(result.gradeColor)
                Text("\(result.totalScore)pt")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
            }
            Text(result.faceShape.note)
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(5)
            Text(result.rankPercentile)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkTertiary)
        }
        .padding(20)
        .hairlineBorder()
    }

    private func scorePreviewList(result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("7 つの評価指標")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkSecondary)

            VStack(spacing: 8) {
                ForEach(Array(result.scores.enumerated()), id: \.element.id) { _, score in
                    HStack {
                        Text(score.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.ivory)
                        Spacer()
                        Text(score.grade)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(score.gradeColor)
                        Text("\(score.score)点")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.inkSecondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                    .overlay(alignment: .bottom) {
                        HairlineDivider().offset(y: 6)
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                appState.skipTutorialOnNextFlow = false
                appState.navigate(to: .diagnosis)
            } label: {
                HStack(spacing: 6) {
                    Text("詳しいレポートを見る")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.ivory)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .hairlineBorder(Theme.Line.outlineIvory)
            }
            .aid("home_report_open_button")

            Button {
                appState.navigate(to: .capture)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("もう一度撮影して評価する")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.ivory)
            }
            .aid("home_report_reeval_button")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "face.dashed")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color.inkSecondary)
            Text("まだ診断結果はありません")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.ivory)
            Text("顔写真を撮ると、ここに 7 つの指標で\nスコアが表示されます。")
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button {
                appState.navigate(to: .capture)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("撮影をはじめる")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.appBackground)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.ivory)
            }
            .padding(.top, 12)
            .aid("home_report_start_button")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    HomeReportTab()
        .environment(AppState())
}
