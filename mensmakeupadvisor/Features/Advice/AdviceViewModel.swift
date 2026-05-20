import SwiftUI
import UIKit

@Observable
@MainActor
final class AdviceViewModel {
    var showCamera = false
    var errorMessage: String?

    func selectImage(_ image: UIImage, appState: AppState) {
        // ピッカー/カメラから来た画像は imageOrientation が .right などになって
        // いることが多い。MediaPipe や MakeupRenderer の座標系を揃えるため、
        // ここで .up に正規化してから以降のパイプラインに流す。
        appState.capturedImage = image.uprightOriented()
        appState.navigate(to: .analyzing)
    }

    func useSample(appState: AppState) {
        // サンプル画像でも MediaPipe を実走させたいので AnalyzingView に流す。
        // 検出失敗時は AnalysisService が .fallback を返す。
        // オンボーディングと同じ実写の顔写真を使う（イラストだと顔検出に失敗するため）。
        let sampleImage = (UIImage(named: "onboarding_face_before") ?? makeSamplePlaceholderImage()).uprightOriented()
        appState.capturedImage = sampleImage
        appState.navigate(to: .analyzing)
    }

    private func makeSamplePlaceholderImage() -> UIImage {
        let size = CGSize(width: 400, height: 533)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            Theme.UIKitColor.sampleBackground.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let faceRect = CGRect(x: 80, y: 60, width: 240, height: 340)
            Theme.UIKitColor.sampleFace.setFill()
            UIBezierPath(ovalIn: faceRect).fill()
            Theme.UIKitColor.sampleShadow.setFill()
            UIBezierPath(ovalIn: CGRect(x: 130, y: 210, width: 45, height: 20)).fill()
            UIBezierPath(ovalIn: CGRect(x: 225, y: 210, width: 45, height: 20)).fill()
            Theme.UIKitColor.sampleAccent.setFill()
            UIBezierPath(ovalIn: CGRect(x: 128, y: 185, width: 50, height: 10)).fill()
            UIBezierPath(ovalIn: CGRect(x: 222, y: 185, width: 50, height: 10)).fill()
            UIBezierPath(ovalIn: CGRect(x: 165, y: 320, width: 70, height: 20)).fill()
            UIBezierPath(ovalIn: CGRect(x: 185, y: 270, width: 30, height: 25)).fill()
        }
    }
}
