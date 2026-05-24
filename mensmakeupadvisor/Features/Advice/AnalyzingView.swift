import SwiftUI
import UIKit

struct AnalyzingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.analysisService) private var analysisService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progress: Double = 0
    @State private var phaseIndex: Int = 0
    @State private var scanY: CGFloat = 0
    @State private var errorMessage: String?
    @State private var errorDetail: String?

    private let phases = ["準備中", "画像を読み込み中", "顔を検出中", "比率を測定中", "完了"]

    var body: some View {
        ZStack {
            LuxeBackground()

            VStack(spacing: 0) {
                topMeta
                    .padding(.top, 56)
                    .padding(.horizontal, 24)

                Spacer()

                if errorMessage != nil {
                    errorContent
                        .padding(.horizontal, 24)
                } else {
                    mainContent
                }

                Spacer()

                if errorMessage == nil {
                    progressSection
                        .padding(.bottom, 56)
                }
            }
        }
        .task { await performAnalysis() }
        .aid("analyzing_view")
    }

    // MARK: - Sections

    private var topMeta: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(errorMessage == nil ? Theme.Plate.renderingTint : Color.brandPrimary)
                    .frame(width: 6, height: 6)
                Text(errorMessage == nil ? "ANALYZING" : "FAILED")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .kerning(2)
                    .foregroundStyle(Theme.Text.primaryFaded)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .glassEffect(.regular, in: .capsule)

            Spacer()

            // 解析中はキャンセル、エラー時は戻るで撮影画面へ。
            // 10〜20 秒待たされる処理を「ここから出られない」状態にはしない。
            if errorMessage == nil {
                Button {
                    Haptics.soft()
                    appState.navigate(to: .capture)
                } label: {
                    Text("キャンセル")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Text.primarySoft)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .glassEffect(.clear, in: .capsule)
                }
                .accessibilityLabel("分析をキャンセルして撮影画面に戻る")
                .aid("analyzing_cancel_button")
            }
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("解析しています")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.ivory)

                Text("顔の比率と骨格を測っています。10〜20 秒ほどかかります。")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 24)

            AnalyzingScanArea(capturedImage: appState.capturedImage, scanY: scanY)
                .padding(.horizontal, 24)
                .onAppear {
                    // Reduce Motion 設定時はスキャンラインを動かさず静的表示。
                    guard !reduceMotion else { return }
                    withAnimation(
                        .linear(duration: 2.0)
                        .repeatForever(autoreverses: false)
                    ) {
                        scanY = 238
                    }
                }
        }
    }

    @ViewBuilder
    private var errorContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.brandPrimary)

                Text(errorMessage ?? "")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.ivory)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail = errorDetail {
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // エラー時の動線はひとつだけ: 撮影画面に戻る。
            // 旧 UI では「もう一度撮影する」と「撮影画面に戻る」が両方 .capture へ
            // 飛ぶ重複ボタンだったので 1 本化した。
            GlassPrimaryButton(
                title: "撮影画面に戻る",
                icon: "camera.fill",
                accessibilityID: "analyzing_retry_button"
            ) {
                Haptics.soft()
                appState.navigate(to: .capture)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(phases[phaseIndex])
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.ivory)
                Text("(\(phaseIndex + 1)/\(phases.count))")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkTertiary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .aid("analyzing_phase_label")

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    HairlineDivider(height: 2)

                    Rectangle()
                        .fill(Color.brandPrimary)
                        .frame(width: geo.size.width * progress, height: 2)
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 2)
            .padding(.horizontal, 24)
            .aid("analyzing_progress_bar")
        }
    }

    // MARK: - Analysis Logic

    private func performAnalysis() async {
        guard let image = appState.capturedImage else {
            showError(
                title: "画像が読み込めませんでした",
                detail: "撮影画面に戻って、もう一度試してください。"
            )
            return
        }

        phaseIndex = 0
        try? await Task.sleep(for: .milliseconds(400))
        withAnimation { progress = 0.20 }

        phaseIndex = 1
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation { progress = 0.40 }

        phaseIndex = 2
        do {
            let result = try await analysisService.analyze(
                image: image, sharedEngine: appState.makeupEngine
            )
            withAnimation { progress = 0.70 }

            phaseIndex = 3
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation { progress = 1.0 }

            phaseIndex = 4
            try? await Task.sleep(for: .milliseconds(400))

            if let cropped = result.croppedImage {
                appState.capturedImage = cropped
            }
            appState.analysisResult = result
            Haptics.success()
            // 3 分岐:
            // 1. Try フロー (Archive → 試す): 診断/チュートリアルを挟まず Studio 直行。
            //    composition は ArchiveViewModel.tryLook で既に保存ルックから組まれている。
            // 2. Create フロー (Home → 撮影): 診断を飛ばして Tutorial で全化粧工程を歩く。
            //    戻り先は Home。フラグは使ったら必ずクリアする。
            // 3. 通常フロー (Onboarding 直後 / Home Report の再評価): Diagnosis に進む。
            if appState.tryingSavedLook {
                appState.navigate(to: .studio)
            } else if appState.skipDiagnosisOnNextFlow {
                appState.skipDiagnosisOnNextFlow = false
                appState.studioOrigin = .home
                appState.navigate(to: .tutorial)
            } else {
                appState.studioOrigin = .diagnosis
                appState.diagnosisOrigin = .capture
                appState.navigate(to: .diagnosis)
            }
        } catch {
            showError(
                title: "顔をうまく検出できませんでした",
                detail: "明るい場所で、正面・前髪なしで撮ると検出しやすくなります。サンプル画像でも試せます。"
            )
        }
    }

    private func showError(title: String, detail: String) {
        errorMessage = title
        errorDetail = detail
    }
}

// MARK: - Preview

#Preview {
    @MainActor func makeState() -> AppState {
        let state = AppState()
        let r = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
        state.capturedImage = r.image { ctx in
            Theme.UIKitColor.previewCanvas.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
        }
        return state
    }
    return AnalyzingView()
        .environment(makeState())
        .environment(\.analysisService, MockAnalysisService())
}
