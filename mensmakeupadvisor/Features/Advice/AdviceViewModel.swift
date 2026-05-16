import SwiftUI
import UIKit

@Observable
@MainActor
final class AdviceViewModel {
    var showImagePicker = false
    var errorMessage: String?

    func selectImage(_ image: UIImage, appState: AppState) {
        appState.capturedImage = image
        appState.navigate(to: .analyzing)
    }

    func useSample(appState: AppState) {
        // アセットから顔サンプル画像を取得、なければプレースホルダーを使用
        let sampleImage = UIImage(named: "sample_face") ?? makeSamplePlaceholderImage()
        appState.capturedImage = sampleImage
        appState.analysisResult = .mock
        appState.navigate(to: .diagnosis)
    }

    private func makeSamplePlaceholderImage() -> UIImage {
        let size = CGSize(width: 400, height: 533)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor(red: 0.12, green: 0.11, blue: 0.09, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let faceRect = CGRect(x: 80, y: 60, width: 240, height: 340)
            UIColor(red: 0.6, green: 0.5, blue: 0.4, alpha: 0.35).setFill()
            UIBezierPath(ovalIn: faceRect).fill()
            UIColor(red: 0.15, green: 0.12, blue: 0.1, alpha: 0.8).setFill()
            UIBezierPath(ovalIn: CGRect(x: 130, y: 210, width: 45, height: 20)).fill()
            UIBezierPath(ovalIn: CGRect(x: 225, y: 210, width: 45, height: 20)).fill()
            UIColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 0.7).setFill()
            UIBezierPath(ovalIn: CGRect(x: 128, y: 185, width: 50, height: 10)).fill()
            UIBezierPath(ovalIn: CGRect(x: 222, y: 185, width: 50, height: 10)).fill()
            UIBezierPath(ovalIn: CGRect(x: 165, y: 320, width: 70, height: 20)).fill()
            UIBezierPath(ovalIn: CGRect(x: 185, y: 270, width: 30, height: 25)).fill()
        }
    }
}
