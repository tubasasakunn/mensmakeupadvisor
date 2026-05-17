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
        @Bindable var bindableState = appState

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
                    showBeforeImage: viewModel.showBeforeImage,
                    intensity: appState.intensity,
                    renderedImage: appState.renderedImage
                )
                .padding(.horizontal, 28)

                ScrollView(.vertical, showsIndicators: false) {
                    TutorialStepInfoArea(
                        currentStep: currentStep,
                        intensity: $bindableState.intensity,
                        eyebrowType: $bindableState.eyebrowType,
                        showBeforeImage: $viewModel.showBeforeImage
                    )
                    .padding(.top, 20)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 8)
                }

                navigationBar
                    .padding(.bottom, 32)
                    .padding(.horizontal, 28)
            }
        }
        .accessibilityElement(children: .contain)
        .aid("tutorial_view")
        .task {
            // 初回入場時に「step 0 まで」適用してから render を要求する。
            if !didInitialize {
                viewModel.resetToFirstStep(appState: appState)
                didInitialize = true
            }
        }
        .task(id: stateKey) {
            await MainActor.run { appState.requestMakeupRender() }
        }
    }

    private var stateKey: String {
        let i = appState.intensity
        let brow = appState.eyebrowType?.rawValue ?? "off"
        let hl = appState.highlightAreas.sorted().joined(separator: ",")
        let sh = appState.shadowAreas.sorted().joined(separator: ",")
        let ey = appState.eyeAreas.sorted().joined(separator: ",")
        return "\(Int(i.base))-\(Int(i.highlight))-\(Int(i.shadow))-\(Int(i.eye))|hl:\(hl)|sh:\(sh)|ey:\(ey)|br:\(brow)"
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
            .aid("tutorial_back_button")

            Spacer()

            Text("ACT \(currentStep.tag) OF \(steps.count)")
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
        case .base:      return Color.ivory.opacity(0.5)
        case .highlight: return Color.ivory
        case .shadow:    return Color.brandPrimary
        case .eye:       return Color.sulphur
        case .eyebrow:   return Color(red: 0.55, green: 0.35, blue: 0.20)
        }
    }

    private var navigationBar: some View {
        let isLast = appState.tutorialStep == max(0, steps.count - 1)

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
}

#Preview {
    TutorialView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
