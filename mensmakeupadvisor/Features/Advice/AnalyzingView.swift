import SwiftUI
import UIKit

struct AnalyzingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.analysisService) private var analysisService

    @State private var progress: Double = 0
    @State private var phaseIndex: Int = 0
    @State private var scanY: CGFloat = 0
    @State private var errorMessage: String?
    @State private var errorDetail: String?

    private let phases = ["準備中", "画像を読み込み中", "顔を検出中", "比率を測定中", "完了"]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

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
            Text(errorMessage == nil ? "分析中" : "分析できませんでした")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.appBackground)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(errorMessage == nil ? Color.ivory.opacity(0.85) : Color.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            Spacer()
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

            VStack(spacing: 10) {
                Button {
                    appState.navigate(to: .capture)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("もう一度撮影する")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.ivory)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .accessibilityLabel("もう一度撮影する")
                .aid("analyzing_retry_button")

                Button {
                    appState.navigate(to: .capture)
                } label: {
                    Text("撮影画面に戻る")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.inkSecondary.opacity(0.35), lineWidth: 1)
                        )
                }
                .aid("analyzing_back_button")
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
                    Rectangle()
                        .fill(Color.lineColor)
                        .frame(height: 2)

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
            appState.navigate(to: .diagnosis)
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
            UIColor(red: 0.2, green: 0.18, blue: 0.15, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
        }
        return state
    }
    return AnalyzingView()
        .environment(makeState())
        .environment(\.analysisService, MockAnalysisService())
}
