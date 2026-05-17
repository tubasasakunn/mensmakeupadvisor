import SwiftData
import SwiftUI
import UIKit

struct TutorialFacePlate: View {
    let currentStep: TutorialStep
    let capturedImage: UIImage?
    let showBeforeImage: Bool
    let intensity: MakeupIntensity
    // 実エンジンが出力した after 画像。AppState.renderedImage を Tutorial 側で
    // bind して渡す。nil の間は capturedImage を表示してフェイクオーバーレイは
    // 出さない (画像の上だけが色変わる現象を避けるため)。
    let renderedImage: UIImage?

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
                } else if let after = renderedImage {
                    Image(uiImage: after)
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

    @ViewBuilder
    private func placeholderFace(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Color(white: 0.10)

            Ellipse()
                .stroke(Color.ivory.opacity(0.25), lineWidth: 1)
                .frame(width: width * 0.55, height: height * 0.68)

            VStack(spacing: 4) {
                Spacer()
                Text("ACT \(currentStep.tag) · \(currentStep.titleJP)")
                    .font(.system(size: 8, weight: .light, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)
                    .padding(.bottom, 12)
            }
        }
    }
}

#Preview {
    TutorialFacePlate(
        currentStep: TutorialStep.sequence(for: .tamago)[0],
        capturedImage: nil,
        showBeforeImage: false,
        intensity: MakeupIntensity(),
        renderedImage: nil
    )
    .padding(28)
    .background(Color.appBackground)
    .modelContainer(for: [SavedLook.self], inMemory: true)
}
