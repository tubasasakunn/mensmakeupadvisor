import SwiftUI
import SwiftData

struct StudioView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StudioViewModel()
    @State private var isRenderingShare = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 8)

                imagePlate
                    .padding(.horizontal, 28)
                    .padding(.top, 12)

                modeSegment
                    .padding(.top, 16)
                    .padding(.horizontal, 28)

                controlPanel
                    .padding(.top, 16)
                    .padding(.horizontal, 28)

                Spacer()

                bottomActions
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
            }

            // 保存通知オーバーレイ
            if viewModel.showSavedNotification {
                savedNotification
            }
        }
        .aid("studio_view")
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            Button {
                appState.navigate(to: .diagnosis)
            } label: {
                Text("← REPORT")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
            }

            Spacer()

            Text("ATELIER · STUDIO")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.ivory)
                .kerning(2)

            Spacer()

            Button {
                appState.navigate(to: .archive)
            } label: {
                Text("SAVED →")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
            }
            .aid("studio_header_saved_button")
        }
        .padding(.horizontal, 28)
    }

    private var imagePlate: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * (5.0 / 4.0)

            ZStack(alignment: .bottomLeading) {
                if viewModel.displayMode == .compare {
                    compareView(width: width, height: height)
                } else {
                    afterView(width: width, height: height)
                }

                // スコア表示
                if let result = appState.analysisResult {
                    scoreChip(result: result)
                        .padding(10)
                }
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .aspectRatio(4.0 / 5.0, contentMode: .fit)
    }

    private func compareView(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            // After（右側）
            afterLayer(width: width, height: height)

            // Before（左側クリップ）
            if let img = appState.capturedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: viewModel.comparePosition * width)
                            Spacer()
                        }
                    )

                // 区切りライン
                Rectangle()
                    .fill(Color.ivory.opacity(0.8))
                    .frame(width: 1, height: height)
                    .offset(x: viewModel.comparePosition * width - 0.5)
            } else {
                placeholderHalf(width: width * viewModel.comparePosition, height: height)
            }

            // Before / After ラベル
            VStack {
                Spacer()
                HStack {
                    Text("FIG. A — BEFORE")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.ivory.opacity(0.7))
                        .kerning(1.2)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                    Spacer()
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("FIG. B — AFTER")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.ivory.opacity(0.7))
                        .kerning(1.2)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                }
            }
        }
        .frame(width: width, height: height)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let fraction = (drag.location.x / width).clamped(to: 0.05...0.95)
                    viewModel.comparePosition = fraction
                }
        )
    }

    private func afterLayer(width: CGFloat, height: CGFloat) -> some View {
        afterView(width: width, height: height)
    }

    private func afterView(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Color.black

            if let img = appState.capturedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                ZStack {
                    Color(white: 0.08)
                    VStack(spacing: 8) {
                        Ellipse()
                            .stroke(Color.lineColor, lineWidth: 1)
                            .frame(width: width * 0.55, height: height * 0.68)
                        Text("AFTER")
                            .font(.system(size: 9, weight: .light, design: .monospaced))
                            .foregroundStyle(Color.inkSecondary)
                            .kerning(3)
                    }
                }
                .frame(width: width, height: height)
            }

            // メイク強度を可視化するグラデーションオーバーレイ
            makeupCompositeOverlay
        }
    }

    private var makeupCompositeOverlay: some View {
        let intensity = appState.intensity
        return ZStack {
            // ハイライト
            LinearGradient(
                colors: [Color.clear, Color.ivory.opacity(intensity.highlight / 250)],
                startPoint: .bottom,
                endPoint: .top
            )
            // シャドウ
            LinearGradient(
                colors: [Color.clear, Color(white: 0.05).opacity(intensity.shadow / 200)],
                startPoint: .center,
                endPoint: .leading
            )
        }
    }

    private func placeholderHalf(width: CGFloat, height: CGFloat) -> some View {
        Color(white: 0.06).frame(width: width, height: height)
    }

    private func scoreChip(result: AnalysisResult) -> some View {
        Text("SCORE \(result.totalScore)")
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(Color.ivory)
            .kerning(1.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.appBackground.opacity(0.7))
            .overlay(
                Rectangle().stroke(Color.lineColor, lineWidth: 1)
            )
    }

    private var modeSegment: some View {
        HStack(spacing: 0) {
            modeButton(title: "COMPARE", mode: .compare, aid: "studio_compare_button")
            modeButton(title: "FINE TUNE", mode: .fineTune, aid: "studio_finetune_button")
        }
        .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
    }

    private func modeButton(title: String, mode: StudioViewModel.DisplayMode, aid: String) -> some View {
        let isActive = viewModel.displayMode == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.displayMode = mode }
        } label: {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .kerning(1.5)
                .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isActive ? Color.ivory : Color.clear)
        }
        .aid(aid)
        .animation(.easeInOut(duration: 0.2), value: viewModel.displayMode)
    }

    @ViewBuilder
    private var controlPanel: some View {
        switch viewModel.displayMode {
        case .compare:
            PresetPanelView(viewModel: viewModel)
        case .fineTune:
            FineTunePanelView()
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 10) {
            archiveButton
            shareButton.frame(width: 52)
        }
    }

    private var archiveButton: some View {
        Button {
            viewModel.saveLook(appState: appState, modelContext: modelContext)
        } label: {
            HStack(spacing: 8) {
                Text("♥")
                    .font(.system(size: 14))
                Text("ARCHIVE THIS LOOK")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .kerning(2)
            }
            .foregroundStyle(Color.ivory)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                Rectangle().stroke(Color.lineStrong, lineWidth: 1)
            )
        }
        .aid("studio_save_button")
    }

    private var shareButton: some View {
        Button {
            Task { await shareCurrentLook() }
        } label: {
            Group {
                if isRenderingShare {
                    ProgressView()
                        .tint(Color.inkSecondary)
                        .scaleEffect(0.7)
                } else {
                    Text("↑")
                        .font(.system(size: 18, weight: .light, design: .monospaced))
                        .foregroundStyle(Color.ivory)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(Rectangle().stroke(Color.lineStrong, lineWidth: 1))
        }
        .aid("studio_share_button")
        .disabled(isRenderingShare)
    }

    private func shareCurrentLook() async {
        guard let result = appState.analysisResult else { return }
        isRenderingShare = true
        defer { isRenderingShare = false }
        let card = DiagnosisShareCardView(result: result)
        if let image = ShareHelper.render(card) {
            ShareHelper.present([image])
        }
    }

    private var savedNotification: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("✓ LOOK ARCHIVED")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.appBackground)
                    .kerning(2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.ivory)
                Spacer()
            }
            .padding(.bottom, 100)
        }
        .aid("studio_saved_notification")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

// MARK: - Preview

#Preview {
    StudioView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
