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

    // 試着中の縦スワイプ用。1 回のドラッグを「Before/After 比較(横)」か
    // 「前後ルック切替(縦)」のどちらか一方に固定し、両者の競合を防ぐ。
    @State private var dragAxis: DragAxis?
    @State private var swipeOffset: CGFloat = 0

    private enum DragAxis { case horizontal, vertical }

    // 試着フローで保存ルックが 2 件以上あるときだけ縦スワイプ切替を有効にする。
    private var canSwipeLooks: Bool {
        appState.tryingSavedLook && appState.triedLooks.count > 1
    }

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
                    .offset(y: canSwipeLooks ? swipeOffset : 0)

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

                if canSwipeLooks {
                    lookPagerOverlay
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
                    .font(.system(size: 12))
                Text("中央をドラッグして比べる")
                    .font(.system(size: 12, weight: .medium))
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
                    .frame(width: 1, height: height)
                    .offset(x: viewModel.comparePosition * width - 0.5)
            } else {
                placeholderHalf(width: width * viewModel.comparePosition, height: height)
            }

            VStack {
                Spacer()
                HStack {
                    Text("Before · 素のまま")
                        .font(.system(size: 11, weight: .semibold))
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
                        .font(.system(size: 11, weight: .semibold))
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
        .gesture(plateGesture(width: width, height: height))
    }

    // 1 本指ドラッグを最初の動きで縦横どちらかに固定する。
    // 横 → Before/After 比較スライダー。縦 → 試着中の前後ルック切替。
    // 試着中で複数ルックが無いときは従来どおり横スクラブのみ。
    private func plateGesture(width: CGFloat, height: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                if dragAxis == nil {
                    let dx = abs(drag.translation.width)
                    let dy = abs(drag.translation.height)
                    if canSwipeLooks, dy > dx, dy > 10 {
                        dragAxis = .vertical
                    } else if dx > 4 || !canSwipeLooks {
                        dragAxis = .horizontal
                    }
                }
                switch dragAxis {
                case .horizontal:
                    let fraction = (drag.location.x / width).clamped(to: 0.05...0.95)
                    viewModel.comparePosition = fraction
                case .vertical:
                    // 端ではゴムのように抵抗をかけ、これ以上めくれないことを示す。
                    swipeOffset = rubberBanded(drag.translation.height)
                case nil:
                    break
                }
            }
            .onEnded { drag in
                if dragAxis == .vertical {
                    let threshold: CGFloat = height * 0.12
                    if drag.translation.height < -threshold {
                        switchLook(offset: 1, animated: true)
                    } else if drag.translation.height > threshold {
                        switchLook(offset: -1, animated: true)
                    } else {
                        withAnimation(.spring(duration: 0.3)) { swipeOffset = 0 }
                    }
                }
                dragAxis = nil
            }
    }

    // 上スワイプ(offset +1)=次、下スワイプ(offset -1)=前。
    // 端で動けなかったら軽い警告触覚で跳ね返す。
    private func switchLook(offset: Int, animated: Bool) {
        let changed = appState.showTriedLook(offset: offset)
        if changed {
            Haptics.selection()
        } else {
            Haptics.warning()
        }
        if animated {
            withAnimation(.spring(duration: 0.35)) { swipeOffset = 0 }
        } else {
            swipeOffset = 0
        }
    }

    // 次/前が無い方向へはオフセットを 1/3 に圧縮して引っ張り抵抗を演出する。
    private func rubberBanded(_ translation: CGFloat) -> CGFloat {
        let atTop = appState.triedLookIndex == 0
        let atBottom = appState.triedLookIndex == appState.triedLooks.count - 1
        if (translation > 0 && atTop) || (translation < 0 && atBottom) {
            return translation / 3
        }
        return translation
    }

    private var lookPagerOverlay: some View {
        VStack {
            HStack(spacing: 5) {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                Text("\(appState.triedLookIndex + 1) / \(appState.triedLooks.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(Theme.Plate.labelText)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.Surface.labelBackdrop)
            .clipShape(Capsule())
            .padding(.top, 10)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("試着中のルック \(appState.triedLookIndex + 1) / \(appState.triedLooks.count) 件")
            .accessibilityHint("上下スワイプで前後のルックに切り替え")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: switchLook(offset: 1, animated: false)
                case .decrement: switchLook(offset: -1, animated: false)
                @unknown default: break
                }
            }
            .aid("studio_try_pager")
            Spacer()
        }
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
                            .stroke(Theme.Plate.placeholderEllipse, lineWidth: 1)
                            .frame(width: width * 0.55, height: height * 0.68)
                        Text("メイク後のプレビュー")
                            .font(.system(size: 11))
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
                        .font(.system(size: 11, weight: .medium))
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
                .font(.system(size: 11))
                .opacity(0.75)
            Text("\(result.totalScore)")
                .font(.system(size: 14, weight: .semibold))
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
