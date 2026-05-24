import SwiftData
import SwiftUI

struct TutorialView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = TutorialViewModel()
    @State private var didInitialize = false
    // step 0 で戻るを押したとき、これまでのレイヤー操作が消えることを明示するため
    // 確認ダイアログを挟む。暗黙 exit は事故の元。
    @State private var showExitConfirmation = false

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
            LuxeBackground()

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 8)

                stepDots
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                // 顔プレートは撮影画像のアスペクト比だけでサイズが決まるよう固定。
                // maxHeight: .infinity を載せると Info 本文量で残り空間が変動し、
                // ステップ間で顔の大きさが揺れていた。
                TutorialFacePlate(
                    currentStep: currentStep,
                    capturedImage: appState.capturedImage,
                    renderedImage: appState.renderedImage
                )
                .padding(.horizontal, 28)

                TutorialStepInfoArea(
                    currentStep: currentStep,
                    intensity: intensityBinding,
                    eyebrowType: $bindableVM.eyebrowType
                )
                .padding(.top, 16)
                .padding(.horizontal, 28)

                Spacer(minLength: 0)

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
        .confirmationDialog(
            "メイクの試着を終わりますか？",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button(exitConfirmationCTA, role: .destructive) {
                Haptics.warning()
                appState.navigate(to: appState.studioOrigin)
            }
            Button("続ける", role: .cancel) {}
        } message: {
            Text("ここまでの調整は保存されません。")
        }
    }

    private var exitConfirmationCTA: String {
        appState.studioOrigin == .home ? "ホームに戻る" : "診断結果に戻る"
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
                } else if appState.tutorialStep == 0 {
                    // 右端スワイプでの暗黙 exit を防ぐ。明示的な確認を求める。
                    showExitConfirmation = true
                } else {
                    viewModel.prevStep(appState: appState)
                }
            }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        let isFirst = appState.tutorialStep == 0
        let backA11y: String = isFirst
            ? "メイクの試着を終わるか確認する"
            : "前のステップに戻る"
        return ScreenHeader(
            variant: .push,
            kicker: "GUIDE \(appState.tutorialStep + 1)/\(steps.count)",
            backAccessibilityLabel: backA11y,
            backAccessibilityID: "tutorial_back_button",
            onBack: {
                // step 0 のときは暗黙的に exit せず、破棄確認を出す。
                if isFirst {
                    showExitConfirmation = true
                } else {
                    viewModel.prevStep(appState: appState)
                }
            }
        )
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

        return GlassPrimaryButton(
            title: isLast ? "スタジオで仕上げる" : "次のステップへ",
            icon: isLast ? "paintbrush.pointed.fill" : nil,
            accessibilityID: "tutorial_next_button"
        ) {
            Haptics.medium()
            // studioOrigin は遷移元 (Diagnosis / Archive) が設定した値を尊重する。
            viewModel.nextStep(appState: appState)
        }
    }
}

#Preview {
    TutorialView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
