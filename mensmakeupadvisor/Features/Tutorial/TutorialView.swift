import SwiftData
import SwiftUI

struct TutorialView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = TutorialViewModel()
    @State private var didInitialize = false

    private var steps: [TutorialStep] { viewModel.steps(for: appState) }

    private var currentStep: TutorialStep {
        let i = max(0, min(appState.tutorialStep, steps.count - 1))
        return steps.isEmpty
            ? TutorialStep.sequence(for: .tamago)[0]
            : steps[i]
    }

    var body: some View {
        @Bindable var bindableVM = viewModel

        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 8)

                stepDots
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                TutorialFacePlate(
                    currentStep: currentStep,
                    capturedImage: appState.capturedImage,
                    renderedImage: appState.renderedImage
                )
                .padding(.horizontal, 28)
                .frame(maxHeight: .infinity)

                TutorialStepInfoArea(
                    currentStep: currentStep,
                    intensity: intensityBinding,
                    eyebrowType: $bindableVM.eyebrowType
                )
                .padding(.top, 16)
                .padding(.horizontal, 28)

                navigationBar
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 28)
            }
        }
        // 進む / 戻るは左右スワイプでも操作できる。
        .contentShape(Rectangle())
        .gesture(swipeGesture)
        .accessibilityElement(children: .contain)
        .aid("tutorial_view")
        .task {
            if !didInitialize {
                viewModel.resetToFirstStep(appState: appState)
                didInitialize = true
            }
        }
        .task(id: renderKey) {
            await viewModel.render(appState: appState)
        }
    }

    // 現在 step の部位だけを調整するスライダー用 binding。
    private var intensityBinding: Binding<Double> {
        Binding(
            get: { viewModel.intensity(for: currentStep) },
            set: { viewModel.setIntensity($0, for: currentStep) }
        )
    }

    // 到達済み step とその強度・眉タイプが変わるたびに再描画する。
    private var renderKey: String {
        let idx = appState.tutorialStep
        let brow = viewModel.eyebrowType?.rawValue ?? "off"
        let vals = steps.prefix(idx + 1)
            .map { String(Int(viewModel.intensity(for: $0))) }
            .joined(separator: ",")
        return "\(idx)|\(brow)|\(vals)"
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy), abs(dx) > 56 else { return }
                if dx < 0 {
                    viewModel.nextStep(appState: appState)
                } else {
                    viewModel.prevStep(appState: appState)
                }
            }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        let isFirst = appState.tutorialStep == 0
        return HStack {
            Button {
                viewModel.prevStep(appState: appState)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text(isFirst ? "診断結果へ" : "前へ")
                        .font(.system(size: 13, weight: .regular))
                }
                .foregroundStyle(Color.inkSecondary)
            }
            .accessibilityLabel(isFirst ? "診断結果に戻る" : "前のステップに戻る")
            .aid("tutorial_back_button")

            Spacer()

            Text("ステップ \(appState.tutorialStep + 1) / \(steps.count)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.ivory)

            Spacer()

            Button {
                viewModel.skip(appState: appState)
            } label: {
                Text("あとで")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.inkSecondary)
            }
            .accessibilityLabel("ガイドを終了してスタジオへ")
            .aid("tutorial_skip_button")
        }
        .padding(.horizontal, 28)
    }

    private var stepDots: some View {
        // 多くなりがちなのでドットは小さく、レイヤー切り替わりで色を変える
        HStack(spacing: 5) {
            ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                Circle()
                    .fill(idx <= appState.tutorialStep ? layerColor(step.layer) : Color.lineColor)
                    .frame(
                        width: idx == appState.tutorialStep ? 7 : 4,
                        height: idx == appState.tutorialStep ? 7 : 4
                    )
                    .animation(.easeInOut(duration: 0.2), value: appState.tutorialStep)
            }
        }
    }

    private func layerColor(_ layer: MakeupLayer) -> Color {
        switch layer {
        case .base:      return Theme.Step.baseDot
        case .highlight: return Color.ivory
        case .shadow:    return Color.brandPrimary
        case .eye:       return Color.sulphur
        case .eyebrow:   return Theme.Accent.eyebrow
        }
    }

    private var navigationBar: some View {
        let isLast = appState.tutorialStep == max(0, steps.count - 1)

        return HStack {
            Spacer()

            Button {
                viewModel.nextStep(appState: appState)
            } label: {
                HStack(spacing: 8) {
                    Text(isLast ? "スタジオで仕上げる" : "次のステップへ")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.appBackground)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.ivory)
            }
            .accessibilityLabel(isLast ? "スタジオで仕上げる" : "次のステップへ")
            .aid("tutorial_next_button")
        }
    }
}

#Preview {
    TutorialView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
