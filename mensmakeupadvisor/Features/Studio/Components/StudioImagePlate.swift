import SwiftData
import SwiftUI
import UIKit

struct StudioImagePlate: View {
    let viewModel: StudioViewModel
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Compare 入場時のオート・デモを 1 回だけ走らせる。スライダーが
    // 動くことを言葉で説明する代わりに、目で覚えてもらう。
    @State private var didPlayCompareIntro = false
    @State private var showCompareHint = false

    // capturedImage 実物のアスペクト比を使う。
    // 顔まわりトリミングで 5:7 などになり得るため、固定 4:5 だと顔が切れる。
    private var displayAspect: CGFloat {
        if let img = appState.capturedImage, img.size.width > 0, img.size.height > 0 {
            return img.size.width / img.size.height
        }
        return 4.0 / 5.0
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width / max(displayAspect, 0.5)

            ZStack {
                compareView(width: width, height: height)

                // スコア表示（右上 — BEFORE/AFTERラベルと重複しない位置）
                if let result = appState.analysisResult {
                    VStack {
                        HStack {
                            Spacer()
                            scoreChip(result: result)
                                .padding(10)
                        }
                        Spacer()
                    }
                }

                if showCompareHint {
                    compareHintOverlay
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .aspectRatio(displayAspect, contentMode: .fit)
        .task {
            if !didPlayCompareIntro {
                didPlayCompareIntro = true
                await playCompareIntro()
            }
        }
    }

    // 左右どちらが Before / After かを身体で覚えてもらう短いデモ。
    // 0.5 → 0.25 → 0.75 → 0.5 とゆっくり振ってから、ヒントテキストを出す。
    // Reduce Motion 設定時はアニメーションせず、ヒントだけ表示する。
    @MainActor
    private func playCompareIntro() async {
        if reduceMotion {
            try? await Task.sleep(for: .milliseconds(400))
            showCompareHint = true
            try? await Task.sleep(for: .seconds(3.0))
            showCompareHint = false
            return
        }
        try? await Task.sleep(for: .milliseconds(400))
        withAnimation(.easeInOut(duration: 0.8)) { viewModel.comparePosition = 0.25 }
        try? await Task.sleep(for: .milliseconds(800))
        withAnimation(.easeInOut(duration: 0.9)) { viewModel.comparePosition = 0.75 }
        try? await Task.sleep(for: .milliseconds(900))
        withAnimation(.easeInOut(duration: 0.6)) { viewModel.comparePosition = 0.5 }
        withAnimation(.easeInOut(duration: 0.3)) { showCompareHint = true }
        try? await Task.sleep(for: .seconds(2.5))
        withAnimation(.easeInOut(duration: 0.4)) { showCompareHint = false }
    }

    private var compareHintOverlay: some View {
        VStack {
            HStack(spacing: 6) {
                Image(systemName: "hand.draw.fill")
                    .font(Theme.Typography.UI.subheadline)
                Text("中央をドラッグして比べる")
                    .font(Theme.Typography.UI.subheadlineMedium)
            }
            .foregroundStyle(Color.appBackground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.Surface.toastBackground)
            .clipShape(Capsule())
            .padding(.top, 12)
            Spacer()
        }
    }

    private func compareView(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            afterLayer(width: width, height: height)

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

                Rectangle()
                    .fill(Theme.Plate.beforeAfterDivider)
                    .frame(width: Theme.Size.Stroke.hairline, height: height)
                    .offset(x: viewModel.comparePosition * width - 0.5)
            } else {
                placeholderHalf(width: width * viewModel.comparePosition, height: height)
            }

            VStack {
                Spacer()
                HStack {
                    Text("Before · 素のまま")
                        .font(Theme.Typography.UI.footnoteSemibold)
                        .foregroundStyle(Theme.Plate.labelText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Surface.labelBackdrop)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                    Spacer()
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("After · メイク後")
                        .font(Theme.Typography.UI.footnoteSemibold)
                        .foregroundStyle(Theme.Plate.labelText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Surface.labelBackdrop)
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
            Theme.Surface.imageBackdrop

            // makeup_claude の MakeupRenderer で実際に化粧が乗った画像があればそれを、
            // まだなければ撮影画像 + 簡易グラデーションを表示。
            if let rendered = appState.renderedImage {
                Image(uiImage: rendered)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else if let img = appState.capturedImage {
                // renderedImage がまだ無いときは撮影画像をそのまま見せる。
                // 以前はここに intensity 連動の LinearGradient をかぶせていたが、
                // 実エンジンが効いていないのに「動いている風」に見えて誤解の元だった。
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                ZStack {
                    Theme.Surface.raised
                    VStack(spacing: 8) {
                        Ellipse()
                            .stroke(Theme.Plate.placeholderEllipse, lineWidth: Theme.Size.Line.regular)
                            .frame(width: width * 0.55, height: height * 0.68)
                        Text("メイク後のプレビュー")
                            .font(Theme.Typography.UI.footnote)
                            .foregroundStyle(Color.inkSecondary)
                    }
                }
                .frame(width: width, height: height)
            }

            if appState.isRenderingMakeup {
                renderingOverlay
            }
        }
    }

    private var renderingOverlay: some View {
        VStack {
            HStack {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(Theme.Plate.renderingTint)
                    Text("反映中…")
                        .font(Theme.Typography.UI.footnoteMedium)
                        .foregroundStyle(Theme.Plate.renderingTint)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.Surface.labelBackdrop)
                Spacer()
            }
            Spacer()
        }
        .padding(8)
    }

    private func placeholderHalf(width: CGFloat, height: CGFloat) -> some View {
        Theme.Surface.sunken.frame(width: width, height: height)
    }

    private func scoreChip(result: AnalysisResult) -> some View {
        HStack(spacing: 4) {
            Text("スコア")
                .font(Theme.Typography.UI.footnote)
                .opacity(0.75)
            Text("\(result.totalScore)")
                .font(Theme.Typography.UI.bodySemibold)
        }
        .foregroundStyle(Color.ivory)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.Surface.labelBackdrop)
        .hairlineBorder()
        .accessibilityLabel("診断スコア \(result.totalScore)")
    }
}

#Preview {
    StudioImagePlate(viewModel: StudioViewModel())
        .padding(28)
        .background(Color.appBackground)
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
