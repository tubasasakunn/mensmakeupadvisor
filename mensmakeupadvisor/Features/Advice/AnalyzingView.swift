import SwiftUI
import UIKit

struct AnalyzingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.analysisService) private var analysisService

    @State private var progress: Double = 0
    @State private var phase: String = "PREPARING"
    @State private var scanY: CGFloat = 0
    @State private var errorMessage: String?

    private let phases = ["PREPARING", "LOADING IMAGE", "DETECTING FACE", "MEASURING PROPORTIONS", "COMPLETE"]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topMeta
                    .padding(.top, 56)
                    .padding(.horizontal, 24)

                Spacer()

                mainContent

                Spacer()

                progressSection
                    .padding(.bottom, 56)
            }
        }
        .task { await performAnalysis() }
        .aid("analyzing_view")
    }

    // MARK: - Sections

    private var topMeta: some View {
        HStack {
            // KBDスタイルラベル
            Text("IN PROGRESS")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.appBackground)
                .kerning(2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.ivory.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 2))

            Spacer()

            if let msg = errorMessage {
                Text(msg)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.brandPrimary)
            }
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // タイトル
            VStack(alignment: .leading, spacing: 4) {
                Text("analysing…")
                    .font(.system(size: 52, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)

                Text("your facial geometry")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
            }
            .padding(.horizontal, 24)

            // 画像プレビュー + スキャンライン
            imageScanArea
                .padding(.horizontal, 24)
        }
    }

    private var imageScanArea: some View {
        ZStack(alignment: .top) {
            // キャプチャ画像（グレースケール暗め）
            capturedImageView
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appBackground.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.lineColor, lineWidth: 1)
                )

            // スキャンライン
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.brandPrimary.opacity(0.6), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: scanY)
                .onAppear {
                    withAnimation(
                        .linear(duration: 2.0)
                        .repeatForever(autoreverses: false)
                    ) {
                        scanY = 238
                    }
                }
                .clipped()

            // メッシュ風グリッドオーバーレイ
            meshOverlay
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(height: 240)
        .clipped()
    }

    @ViewBuilder
    private var capturedImageView: some View {
        if let image = appState.capturedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .saturation(0.0)
                .brightness(-0.1)
                .contrast(0.9)
        } else {
            Rectangle()
                .fill(Color.white.opacity(0.04))
        }
    }

    private var meshOverlay: some View {
        Canvas { context, size in
            let cols = 8
            let rows = 10
            let cellW = size.width / CGFloat(cols)
            let cellH = size.height / CGFloat(rows)

            for col in 0...cols {
                var path = Path()
                let x = CGFloat(col) * cellW
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(Color.ivory.opacity(0.08)), lineWidth: 0.5)
            }
            for row in 0...rows {
                var path = Path()
                let y = CGFloat(row) * cellH
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color.ivory.opacity(0.08)), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // フェーズラベル
            HStack {
                ForEach(phases, id: \.self) { p in
                    Text(p == phase ? p : "·")
                        .font(.system(size: 9, weight: p == phase ? .medium : .regular, design: .monospaced))
                        .foregroundStyle(p == phase ? Color.ivory : Color.inkTertiary)
                        .kerning(1)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .aid("analyzing_phase_label")

            // プログレスバー（底部の細い赤いライン）
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
            errorMessage = "画像が取得できませんでした"
            return
        }

        // Phase 1: PREPARING (0 → 20%)
        phase = "PREPARING"
        try? await Task.sleep(for: .milliseconds(400))
        withAnimation { progress = 0.20 }

        // Phase 2: LOADING IMAGE (20 → 40%)
        phase = "LOADING IMAGE"
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation { progress = 0.40 }

        // Phase 3: DETECTING FACE → API呼び出し (40 → 70%)
        phase = "DETECTING FACE"
        do {
            let result = try await analysisService.analyze(image: image)
            withAnimation { progress = 0.70 }

            // Phase 4: MEASURING PROPORTIONS (70 → 100%)
            phase = "MEASURING PROPORTIONS"
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation { progress = 1.0 }

            // Phase 5: COMPLETE
            phase = "COMPLETE"
            try? await Task.sleep(for: .milliseconds(400))

            appState.analysisResult = result
            appState.navigate(to: .diagnosis)
        } catch {
            errorMessage = "解析に失敗しました"
        }
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
