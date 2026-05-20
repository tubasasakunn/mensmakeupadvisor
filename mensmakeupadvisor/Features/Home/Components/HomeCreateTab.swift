import SwiftUI

// 化粧作成タブ。タップで撮影 → 分析 → Studio (Tutorial スキップ) のフローへ。
struct HomeCreateTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, 32)
                titleSection
                    .padding(.top, 12)
                dividerLine
                    .padding(.top, 24)

                Spacer()

                heroBlock
                    .padding(.vertical, 32)

                Spacer()

                primaryButton
                lastPresetHint
                    .padding(.top, 16)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 60)
        }
        .aid("home_create_tab")
    }

    private var headerSection: some View {
        Text("新しく撮影する")
            .font(.system(size: 12))
            .foregroundStyle(Color.inkSecondary)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("メイクを試す")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.ivory)
        }
    }

    private var dividerLine: some View {
        Rectangle().fill(Color.lineColor).frame(height: 1)
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("3 ステップで完了")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkSecondary)
            Text("自分の顔を撮って、\nメイクを試してみる。")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.ivory)
                .lineSpacing(4)
            HStack(spacing: 6) {
                heroStep(number: "1", label: "撮影")
                heroArrow
                heroStep(number: "2", label: "診断")
                heroArrow
                heroStep(number: "3", label: "メイク")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func heroStep(number: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(number)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .italic()
                .foregroundStyle(Color.brandPrimary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkSecondary)
        }
    }

    private var heroArrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(Color.inkTertiary)
    }

    private var primaryButton: some View {
        Button {
            appState.skipTutorialOnNextFlow = true
            appState.navigate(to: .capture)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("カメラで撮影する")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.appBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.ivory)
        }
        .accessibilityLabel("カメラで撮影する")
        .aid("home_create_camera_button")
    }

    private var lastPresetHint: some View {
        HStack {
            if let result = appState.analysisResult {
                Text("前回の診断: \(result.faceShape.label) · \(result.grade)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkTertiary)
            } else {
                Text("初回の撮影です")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkTertiary)
            }
            Spacer()
        }
    }
}

#Preview {
    HomeCreateTab()
        .environment(AppState())
}
