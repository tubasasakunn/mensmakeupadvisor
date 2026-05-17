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
                    dividerLine
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
        Text("YOUR FACE · REPORT")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.inkSecondary)
            .kerning(2.5)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("your face.")
                .font(.system(size: 38, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.brandPrimary)

            Text("評価レポート.")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
        }
    }

    private var dividerLine: some View {
        Rectangle().fill(Color.lineColor).frame(height: 1)
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
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkTertiary)
                .kerning(1.2)
        }
        .padding(20)
        .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
    }

    private func scorePreviewList(result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("7 CRITERIA")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2.5)

            VStack(spacing: 8) {
                ForEach(Array(result.scores.enumerated()), id: \.element.id) { _, score in
                    HStack {
                        Text(score.name)
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .italic()
                            .foregroundStyle(Color.ivory)
                        Spacer()
                        Text(score.grade)
                            .font(.system(size: 14, weight: .light, design: .serif))
                            .italic()
                            .foregroundStyle(score.gradeColor)
                        Text("\(score.score)pt")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.inkSecondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color.lineColor).frame(height: 1).offset(y: 6)
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                appState.navigate(to: .diagnosis)
            } label: {
                Text("詳細レポートを開く →")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.ivory)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(Rectangle().stroke(Color.ivory.opacity(0.35), lineWidth: 1))
            }
            .aid("home_report_open_button")

            Button {
                appState.navigate(to: .capture)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("再評価する")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
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
            Text("⊕")
                .font(.system(size: 32))
                .foregroundStyle(Color.inkSecondary)
            Text("まだ、評価結果はありません")
                .font(.system(size: 14, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
            Text("最初の顔評価から始めましょう。")
                .font(.system(size: 11))
                .foregroundStyle(Color.inkSecondary)

            Button {
                appState.navigate(to: .capture)
            } label: {
                Text("評価を始める →")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
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
