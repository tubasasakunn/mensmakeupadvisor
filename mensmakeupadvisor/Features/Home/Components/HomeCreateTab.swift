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
        Text("CREATE · NEW LOOK")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.inkSecondary)
            .kerning(2.5)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("compose.")
                .font(.system(size: 38, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.brandPrimary)
            Text("新しいルック.")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
        }
    }

    private var dividerLine: some View {
        Rectangle().fill(Color.lineColor).frame(height: 1)
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("01 · 撮影")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)
            Text("自分の顔を撮る。\n顔の比率から、\nメイクを設計する。")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
                .lineSpacing(4)
            Text("· 撮影 → 7 指標で評価 → スタジオで調整 ·")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkTertiary)
                .kerning(1.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryButton: some View {
        Button {
            // ホーム→Create では Tutorial をスキップして直接スタジオまで進む。
            // (Tutorial フラグは AnalyzingView 後のナビ分岐に使う)
            appState.skipTutorialOnNextFlow = true
            appState.navigate(to: .capture)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("カメラで撮影する")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .kerning(0.5)
                Text("→")
                    .font(.system(size: 14, design: .monospaced))
            }
            .foregroundStyle(Color.appBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.ivory)
        }
        .aid("home_create_camera_button")
    }

    private var lastPresetHint: some View {
        HStack {
            if let result = appState.analysisResult {
                Text("前回: \(result.faceShape.label) · \(result.grade)")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkTertiary)
                    .kerning(1)
            } else {
                Text("はじめての撮影")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkTertiary)
                    .kerning(1)
            }
            Spacer()
        }
    }
}

#Preview {
    HomeCreateTab()
        .environment(AppState())
}
