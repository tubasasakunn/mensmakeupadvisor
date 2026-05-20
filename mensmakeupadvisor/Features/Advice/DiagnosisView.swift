import SwiftUI
import UIKit

struct DiagnosisView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        reportHeader
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                        titleBlock
                            .padding(.top, 12)
                            .padding(.horizontal, 24)

                        captionLine
                            .padding(.top, 8)
                            .padding(.horizontal, 24)

                        dividerLine
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                        DiagnosisHeroSection(result: result)
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        // スコアを見た直後の「シェアしたい」瞬間に配置
                        DiagnosisSharePrompt(result: result, capturedImage: appState.capturedImage)
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                        DiagnosisFaceMeshPlate(capturedImage: appState.capturedImage, result: result)
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                        DiagnosisProportionPlate(capturedImage: appState.capturedImage, result: result)
                            .padding(.top, 16)
                            .padding(.horizontal, 24)

                        dividerLine
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        DiagnosisScoreListSection(result: result, capturedImage: appState.capturedImage)
                            .padding(.top, 4)
                            .padding(.horizontal, 24)

                        bottomButtons
                            .padding(.top, 32)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 56)
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

    private var navigationBar: some View {
        HStack {
            Button {
                appState.navigate(to: .capture)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("撮影に戻る")
                        .font(.system(size: 13, weight: .regular))
                }
                .foregroundStyle(Color.inkSecondary)
            }
            .accessibilityLabel("撮影画面に戻る")
            .aid("diagnosis_back_button")

            Spacer()

            Text("診断結果")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkSecondary)
                .kerning(1)
        }
    }

    // MARK: - Header

    private var reportHeader: some View {
        Text("CHAPTER 07 · RESULT")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.inkSecondary)
            .kerning(2.5)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("step two.")
                .font(.system(size: 38, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.brandPrimary)

            Text("診断結果.")
                .font(.system(size: 44, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
        }
    }

    private var captionLine: some View {
        Text("— a study of seven proportions —")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.inkSecondary)
            .kerning(1.5)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.lineColor)
            .frame(height: 1)
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        let isSkipFlow = appState.skipTutorialOnNextFlow
        return VStack(spacing: 12) {
            Button {
                if isSkipFlow {
                    appState.skipTutorialOnNextFlow = false
                    appState.navigate(to: .studio)
                } else {
                    appState.navigate(to: .tutorial)
                }
            } label: {
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text(isSkipFlow ? "スタジオを開く" : "メイクを試してみる")
                            .font(.system(size: 16, weight: .semibold))
                        Text("→")
                            .font(.system(size: 15, weight: .regular))
                    }
                    Text(isSkipFlow ? "すぐにプリセットや細かい調整ができます" : "5ステップのガイドに沿って進めます")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Theme.Text.onAccentSoft)
                }
                .foregroundStyle(Color.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.ivory)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .accessibilityLabel(isSkipFlow ? "スタジオを開く。すぐにプリセットや細かい調整ができます" : "メイクを試してみる。5ステップのガイドに沿って進めます")
            .aid("diagnosis_begin_button")

            if !isSkipFlow {
                Button {
                    appState.navigate(to: .studio)
                } label: {
                    VStack(spacing: 2) {
                        Text("ガイドを飛ばしてスタジオへ")
                            .font(.system(size: 14, weight: .medium))
                        Text("メイクの経験がある方向け")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Theme.Text.secondaryFaded)
                    }
                    .foregroundStyle(Color.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Theme.Line.outlineSoft, lineWidth: 1)
                    )
                }
                .accessibilityLabel("ガイドを飛ばしてスタジオへ。メイクの経験がある方向け")
                .aid("diagnosis_skip_button")
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
