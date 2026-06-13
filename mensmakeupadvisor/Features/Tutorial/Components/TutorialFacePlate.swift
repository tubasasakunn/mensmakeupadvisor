import SwiftData
import SwiftUI
import UIKit

struct TutorialFacePlate: View {
    let currentStep: TutorialStep
    let capturedImage: UIImage?
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
                Theme.Surface.imageBackdrop
                faceImage(width: width, height: height)
                stepTag
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .aspectRatio(displayAspect, contentMode: .fit)
    }

    @ViewBuilder
    private func faceImage(width: CGFloat, height: CGFloat) -> some View {
        if let after = renderedImage {
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
            .font(Theme.Typography.Data.baseLight)
            .foregroundStyle(Theme.Step.labelTag)
            .padding(10)
    }

    @ViewBuilder
    private func placeholderFace(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Theme.Surface.raised

            Ellipse()
                .stroke(Theme.Plate.placeholderEllipse, lineWidth: Theme.Size.Line.regular)
                .frame(width: width * 0.55, height: height * 0.68)

            VStack(spacing: 4) {
                Spacer()
                Text("ステップ \(currentStep.tagNumeric) · \(currentStep.titleJP)")
                    .font(Theme.Typography.UI.footnoteMedium)
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.bottom, 12)
            }
        }
    }
}

#Preview {
    TutorialFacePlate(
        currentStep: TutorialStep.sequence(for: .tamago)[0],
        capturedImage: nil,
        renderedImage: nil
    )
    .padding(28)
    .background(Color.appBackground)
    .modelContainer(for: [SavedLook.self], inMemory: true)
}
