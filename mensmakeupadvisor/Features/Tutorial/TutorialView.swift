import SwiftData
import SwiftUI

struct TutorialView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = TutorialViewModel()

    private var currentStep: TutorialStep { TutorialStep.all[appState.tutorialStep] }

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
                    intensity: appState.intensity
                )
                .padding(.horizontal, 28)

                TutorialStepInfoArea(
                    currentStep: currentStep,
                    intensity: $bindableState.intensity,
                    showBeforeImage: $viewModel.showBeforeImage
                )
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
            .aid("tutorial_back_button")

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

// MARK: - Preview

#Preview {
    TutorialView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
