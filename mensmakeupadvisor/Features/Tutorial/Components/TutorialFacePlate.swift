import SwiftData
import SwiftUI
import UIKit

struct TutorialFacePlate: View {
    let currentStep: TutorialStep
    let capturedImage: UIImage?
    let showBeforeImage: Bool
    let intensity: MakeupIntensity

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * (5.0 / 4.0)

            ZStack(alignment: .topLeading) {
                Color.black

                if showBeforeImage, let img = capturedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                } else if let img = capturedImage {
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

                Text(currentStep.tag)
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundStyle(Color.ivory.opacity(0.6))
                    .padding(10)

                if showBeforeImage {
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
        let opacity = intensity[layer] / 200.0

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
}

#Preview {
    TutorialFacePlate(
        currentStep: TutorialStep.all[0],
        capturedImage: nil,
        showBeforeImage: false,
        intensity: MakeupIntensity()
    )
    .padding(28)
    .background(Color.appBackground)
    .modelContainer(for: [SavedLook.self], inMemory: true)
}
