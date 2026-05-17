import SwiftData
import SwiftUI
import UIKit

struct TutorialFacePlate: View {
    let currentStep: TutorialStep
    let capturedImage: UIImage?
    let showBeforeImage: Bool
    let intensity: MakeupIntensity
    // 実エンジンが出力した after 画像。nil の間は capturedImage を表示。
    let renderedImage: UIImage?

    // 顔まわりトリミング後の画像は ~5:7 など 4:5 と微妙にズレることがある。
    // プレート枠を画像の実アスペクトに合わせて、額・あごが切れないようにする。
    private var displayAspect: CGFloat {
        if let img = capturedImage, img.size.width > 0, img.size.height > 0 {
            return img.size.width / img.size.height
        }
        return 4.0 / 5.0
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width / max(displayAspect, 0.5)

            ZStack(alignment: .topLeading) {
                Color.black
                faceImage(width: width, height: height)
                stepTag
                if showBeforeImage { beforeLabel }
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .aspectRatio(displayAspect, contentMode: .fit)
    }

    @ViewBuilder
    private func faceImage(width: CGFloat, height: CGFloat) -> some View {
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
    }

    private var stepTag: some View {
        Text(currentStep.tag)
            .font(.system(size: 11, weight: .light, design: .monospaced))
            .foregroundStyle(Color.ivory.opacity(0.6))
            .padding(10)
    }

    private var beforeLabel: some View {
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
