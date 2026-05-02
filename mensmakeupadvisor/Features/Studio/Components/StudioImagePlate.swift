import SwiftData
import SwiftUI
import UIKit

struct StudioImagePlate: View {
    let viewModel: StudioViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * (5.0 / 4.0)

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
        .aspectRatio(4.0 / 5.0, contentMode: .fit)
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
                    Color(white: 0.10)
                    VStack(spacing: 8) {
                        Ellipse()
                            .stroke(Color.ivory.opacity(0.25), lineWidth: 1)
                            .frame(width: width * 0.55, height: height * 0.68)
                        Text("FIG. B · AFTER")
                            .font(.system(size: 8, weight: .light, design: .monospaced))
                            .foregroundStyle(Color.inkSecondary)
                            .kerning(2)
                    }
                }
                .frame(width: width, height: height)
            }

            makeupCompositeOverlay
        }
    }

    private var makeupCompositeOverlay: some View {
        let intensity = appState.intensity
        return ZStack {
            LinearGradient(
                colors: [Color.clear, Color.ivory.opacity(intensity.highlight / 250)],
                startPoint: .bottom,
                endPoint: .top
            )
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
}

#Preview {
    StudioImagePlate(viewModel: StudioViewModel())
        .padding(28)
        .background(Color.appBackground)
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
