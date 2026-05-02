import SwiftData
import SwiftUI

struct TutorialView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = TutorialViewModel()

    private var currentStep: TutorialStep { TutorialStep.all[appState.tutorialStep] }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 8)

                stepDots
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                facePlate
                    .padding(.horizontal, 28)

                stepInfoArea
                    .padding(.top, 20)
                    .padding(.horizontal, 28)

                Spacer()

                navigationBar
                    .padding(.bottom, 32)
                    .padding(.horizontal, 28)
            }
        }
        .aid("tutorial_view")
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            Button {
                viewModel.prevStep(appState: appState)
            } label: {
                Text("← BACK")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
            }

            Spacer()

            Text("ACT \(romanNumeral(appState.tutorialStep + 1)) OF V")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.ivory)
                .kerning(1.5)

            Spacer()

            Button {
                viewModel.skip(appState: appState)
            } label: {
                Text("SKIP →")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
            }
            .aid("tutorial_skip_button")
        }
        .padding(.horizontal, 28)
    }

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(TutorialStep.all) { step in
                Circle()
                    .fill(step.id <= appState.tutorialStep ? Color.ivory : Color.lineColor)
                    .frame(
                        width: step.id == appState.tutorialStep ? 8 : 5,
                        height: step.id == appState.tutorialStep ? 8 : 5
                    )
                    .animation(.easeInOut(duration: 0.2), value: appState.tutorialStep)
            }
        }
    }

    private var facePlate: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * (5.0 / 4.0)

            ZStack(alignment: .topLeading) {
                // 背景
                Color.black

                // 画像 or プレースホルダー
                if viewModel.showBeforeImage, let img = appState.capturedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                } else if let img = appState.capturedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                        // メイクレイヤー強度のオーバーレイ表示（抽象的）
                        .overlay(makeupOverlay)
                } else {
                    placeholderFace(width: width, height: height)
                }

                // 角のローマ数字
                Text(currentStep.tag)
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundStyle(Color.ivory.opacity(0.6))
                    .padding(10)

                // BEFORE ラベル（押し中のみ表示）
                if viewModel.showBeforeImage {
                    VStack {
                        Spacer()
                        HStack {
                            Text("FIG. A — BEFORE")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.ivory.opacity(0.7))
                                .kerning(1.5)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            Spacer()
                        }
                    }
                }
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .aspectRatio(4.0 / 5.0, contentMode: .fit)
    }

    private var makeupOverlay: some View {
        let layer = currentStep.layer
        let intensity = appState.intensity[layer]
        let opacity = intensity / 200.0

        return Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, overlayColor(for: layer).opacity(opacity)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
    }

    @ViewBuilder
    private func placeholderFace(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Color(white: 0.10)

            Ellipse()
                .stroke(Color.ivory.opacity(0.25), lineWidth: 1)
                .frame(width: width * 0.55, height: height * 0.68)

            VStack(spacing: 4) {
                Spacer()
                Text("ACT \(currentStep.tag) · \(currentStep.label.uppercased())")
                    .font(.system(size: 8, weight: .light, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)
                    .padding(.bottom, 12)
            }
        }
    }

    private func overlayColor(for layer: MakeupLayer) -> Color {
        switch layer {
        case .highlight: Color.ivory
        case .shadow:    Color(white: 0.1)
        case .base:      Color(red: 0.85, green: 0.72, blue: 0.6)
        case .eye:       Color(red: 0.2, green: 0.15, blue: 0.3)
        case .eyebrow:   Color(red: 0.3, green: 0.22, blue: 0.15)
        }
    }

    private var stepInfoArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ステップ情報
            VStack(alignment: .leading, spacing: 6) {
                Text("ACT \(currentStep.tag)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)

                Text("\(currentStep.label).")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
            }
            .aid("tutorial_step_info")

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.vertical, 14)

            Text(currentStep.desc)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            // INTENSITY スライダー
            intensitySlider
                .padding(.top, 20)

            // HOLD → BEFORE ボタン
            beforeButton
                .padding(.top, 16)
        }
    }

    private var intensitySlider: some View {
        let layer = currentStep.layer
        let intensityValue = appState.intensity[layer]
        let binding = Binding<Double>(
            get: { appState.intensity[layer] },
            set: { appState.intensity[layer] = $0 }
        )

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("INTENSITY")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)

                Text(String(format: "%.0f", intensityValue))
                    .font(.system(size: 36, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
            }

            // カスタムスライダー
            CustomIntensitySlider(
                value: binding,
                range: 0...100
            )
            .aid("tutorial_intensity_slider")

            HStack {
                Text("OFF")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("· 50 ·")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("MAX")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
    }

    private var beforeButton: some View {
        Button {
            // ロングプレス想定だが、タップトグルで代替
        } label: {
            Text("HOLD → BEFORE")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(viewModel.showBeforeImage ? Color.appBackground : Color.ivory)
                .kerning(1.5)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewModel.showBeforeImage ? Color.ivory : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.lineStrong, lineWidth: 1)
                )
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.1)
                .onChanged { _ in viewModel.showBeforeImage = true }
                .onEnded { _ in viewModel.showBeforeImage = false }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in viewModel.showBeforeImage = false }
        )
        .aid("tutorial_before_button")
    }

    private var navigationBar: some View {
        let isLast = appState.tutorialStep == TutorialStep.all.count - 1

        return HStack {
            Spacer()

            Button {
                viewModel.nextStep(appState: appState)
            } label: {
                Text(isLast ? "COMPOSE →" : "NEXT ACT →")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.appBackground)
                    .kerning(1.5)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.ivory)
            }
            .aid("tutorial_next_button")
        }
    }

    // MARK: - Helpers

    private func romanNumeral(_ n: Int) -> String {
        switch n {
        case 1: "I"
        case 2: "II"
        case 3: "III"
        case 4: "IV"
        case 5: "V"
        default: "\(n)"
        }
    }
}

// MARK: - Custom Slider

private struct CustomIntensitySlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let handleX = fraction * width

            ZStack(alignment: .leading) {
                // トラック
                Rectangle()
                    .fill(Color.lineColor)
                    .frame(height: 1)

                // アクティブ部分
                Rectangle()
                    .fill(Color.ivory.opacity(0.6))
                    .frame(width: handleX, height: 1)

                // ハンドル
                Rectangle()
                    .fill(Color.ivory)
                    .frame(width: 8, height: 16)
                    .offset(x: handleX - 4)
            }
            .contentShape(Rectangle().size(CGSize(width: width, height: 44)).offset(y: -22))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let fraction = (drag.location.x / width)
                            .clamped(to: 0...1)
                        value = range.lowerBound + fraction * (range.upperBound - range.lowerBound)
                    }
            )
        }
        .frame(height: 16)
    }
}

// MARK: - Comparable clamped helper

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

// MARK: - Preview

#Preview {
    TutorialView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
