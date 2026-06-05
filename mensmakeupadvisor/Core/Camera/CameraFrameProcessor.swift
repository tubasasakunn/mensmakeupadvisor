import AVFoundation
import CoreImage
import CoreVideo
import UIKit

// AVCaptureVideoDataOutput のサンプルバッファを向き補正済みの UIImage に変換し、
// AsyncStream で流すデリゲート。化粧合成 (detect + render) は重いので、ここでは
// 変換のみ行い、合成は CameraSessionController 側でスロットリングして実行する。
//
// captureOutput は AVFoundation のバックグラウンドキューで呼ばれる。共有可変状態を
// 持たず (継続と再利用する CIContext のみ)、Sendable な UIImage を yield して
// MainActor 側と通信するため、@unchecked Sendable を使わずに Swift 6 と両立する。
final class CameraFrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let stream: AsyncStream<UIImage>
    private let continuation: AsyncStream<UIImage>.Continuation
    private let ciContext = CIContext(options: nil)

    override init() {
        var captured: AsyncStream<UIImage>.Continuation!
        // 最新フレームだけ保持。合成が追いつかなくても遅延を溜めない。
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

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        // pixelBuffer は AVFoundation に再利用されるので、ここで CGImage に焼いて切り離す。
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }

        // フロントカメラ・ポートレートの向き。.leftMirrored を焼き込んで以降の
        // detect / render が一貫して扱えるようにする。実機で上下左右がずれる場合は
        // この orientation が調整点 (シミュレータでは検証不可)。
        let oriented = UIImage(cgImage: cgImage, scale: 1, orientation: .leftMirrored)
            .uprightOriented()
        continuation.yield(oriented)
    }
}
