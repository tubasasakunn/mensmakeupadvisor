import AVFoundation
import CoreVideo
import Vision

// AVCaptureVideoDataOutput のサンプルバッファを受け取り、Vision で顔ランドマークを
// 検出して FaceObservation を AsyncStream に流すデリゲート。
//
// captureOutput は AVFoundation が管理するバックグラウンドキューで呼ばれる。
// 共有する可変状態を持たず (継続のみ保持)、検出結果は Sendable な FaceObservation に
// 落としてから yield するため、@unchecked Sendable を使わずに Swift 6 strict
// concurrency と両立する。継続経由でのみ MainActor 側 (CameraSessionController) と
// 通信する。
final class CameraFrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let stream: AsyncStream<FaceObservation?>
    private let continuation: AsyncStream<FaceObservation?>.Continuation

    override init() {
        var captured: AsyncStream<FaceObservation?>.Continuation!
        // 最新フレームだけ保持。描画が追いつかなくても遅延が溜まらないようにする。
        stream = AsyncStream(bufferingPolicy: .bufferingNewest(1)) { captured = $0 }
        continuation = captured
        super.init()
    }

    func finish() {
        continuation.finish()
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // フロントカメラ・ポートレート時の向き。実機での見え方に応じて
        // .leftMirrored / .upMirrored などへ要調整 (シミュレータでは検証不可)。
        let orientation: CGImagePropertyOrientation = .leftMirrored

        // 向き補正後の画像サイズ。.left*/.right* は 90° 回転なので幅高を入れ替える。
        let rawW = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let rawH = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let orientedSize: CGSize
        switch orientation {
        case .left, .right, .leftMirrored, .rightMirrored:
            orientedSize = CGSize(width: rawH, height: rawW)
        default:
            orientedSize = CGSize(width: rawW, height: rawH)
        }

        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            continuation.yield(nil)
            return
        }

        if let face = request.results?.first {
            continuation.yield(FaceObservation(visionFace: face, orientedImageSize: orientedSize))
        } else {
            continuation.yield(nil)
        }
    }
}
