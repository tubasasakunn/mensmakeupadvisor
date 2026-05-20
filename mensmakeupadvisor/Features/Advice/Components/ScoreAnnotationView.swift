import SwiftUI
import UIKit

// 各 FaceScore ごとに、評価対象の部位を撮影画像の上に線で示す。
// ScoreCardView の expand 時に出すための部品。実描画は ScoreAnnotationDrawer。
struct ScoreAnnotationView: View {
    let scoreName: String
    let capturedImage: UIImage?
    let landmarks: [CGPoint]?

    var body: some View {
        GeometryReader { geo in
            content(in: geo.size)
        }
        .aspectRatio(imageAspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .hairlineBorder(cornerRadius: 4)
    }

    private var imageAspect: CGFloat {
        if let img = capturedImage, img.size.width > 0, img.size.height > 0 {
            return img.size.width / img.size.height
        }
        return 4.0 / 5.0
    }

    @ViewBuilder
    private func content(in size: CGSize) -> some View {
        ZStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .overlay(Theme.Surface.imageDim)
            } else {
                Rectangle().fill(Theme.Surface.glassMedium)
            }

            if let landmarks, landmarks.count >= 478 {
                annotationCanvas(landmarks: landmarks)
            }
        }
    }

    private func annotationCanvas(landmarks: [CGPoint]) -> some View {
        Canvas { context, size in
            let drawer = ScoreAnnotationDrawer(context: context, size: size, landmarks: landmarks)
            switch scoreName {
            case "骨格バランス": drawer.drawSkeletalBalance()
            case "三分割比率":   drawer.drawVerticalThirds()
            case "五分割比率":   drawer.drawHorizontalFifths()
            case "目の比率":     drawer.drawEyeRatio()
            case "鼻のバランス": drawer.drawNoseBalance()
            case "口の比率":     drawer.drawMouthRatio()
            case "左右対称性":   drawer.drawSymmetry()
            default: break
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ScoreAnnotationView(scoreName: "目の比率", capturedImage: nil, landmarks: nil)
        .padding(24)
        .background(Color.appBackground)
}
