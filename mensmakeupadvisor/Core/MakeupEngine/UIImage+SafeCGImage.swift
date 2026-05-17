import CoreImage
import UIKit

extension UIImage {
    // `cgImage` が nil の場合 (CIImage 経由生成画像) でも CGImage を取得するためのフォールバック。
    nonisolated var safeCGImage: CGImage? {
        if let img = cgImage { return img }
        guard let ci = ciImage else { return nil }
        let ctx = CIContext(options: nil)
        return ctx.createCGImage(ci, from: ci.extent)
    }
}
