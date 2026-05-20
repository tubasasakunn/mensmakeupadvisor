import SwiftData
import SwiftUI
import UIKit

struct StudioImagePlate: View {
    let viewModel: StudioViewModel
    @Environment(AppState.self) private var appState

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
                if viewModel.displayMode == .compare {
                    compareView(width: width, height: height)
                } else {
                    afterView(width: width, height: height)
                }

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
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .aspectRatio(displayAspect, contentMode: .fit)
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
                    .fill(Color.ivory.opacity(0.8))
                    .frame(width: 1, height: height)
                    .offset(x: viewModel.comparePosition * width - 0.5)
            } else {
                placeholderHalf(width: width * viewModel.comparePosition, height: height)
            }

            VStack {
                Spacer()
                HStack {
                    Text("Before · 素のまま")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.ivory.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.appBackground.opacity(0.55))
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
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.ivory.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.appBackground.opacity(0.55))
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
                    Color(white: 0.10)
                    VStack(spacing: 8) {
                        Ellipse()
                            .stroke(Color.ivory.opacity(0.25), lineWidth: 1)
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
                        .tint(Color.ivory.opacity(0.85))
                    Text("反映中…")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.ivory.opacity(0.85))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.appBackground.opacity(0.6))
                Spacer()
            }
            Spacer()
        }
        .padding(8)
    }

    private func placeholderHalf(width: CGFloat, height: CGFloat) -> some View {
        Color(white: 0.06).frame(width: width, height: height)
    }

    private func scoreChip(result: AnalysisResult) -> some View {
        HStack(spacing: 4) {
            Text("スコア")
                .font(.system(size: 10))
                .opacity(0.75)
            Text("\(result.totalScore)")
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(Color.ivory)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.appBackground.opacity(0.7))
        .overlay(
            Rectangle().stroke(Color.lineColor, lineWidth: 1)
        )
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
