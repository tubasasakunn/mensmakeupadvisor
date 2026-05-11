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

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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

        phase = "PREPARING"
        try? await Task.sleep(for: .milliseconds(400))
        withAnimation { progress = 0.20 }

        phase = "LOADING IMAGE"
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation { progress = 0.40 }

        phase = "DETECTING FACE"
        do {
            let result = try await analysisService.analyze(
                image: image, sharedEngine: appState.makeupEngine
            )
            withAnimation { progress = 0.70 }

            phase = "MEASURING PROPORTIONS"
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation { progress = 1.0 }

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
