import UIKit

extension UIImage {
    // UIImage は imageOrientation メタを持ち、表示時にだけ自動回転される。
    // 一方 CGImage / MediaPipe MPImage はピクセル配列を直接扱うため、
    // imageOrientation != .up のままだと「ユーザーが見ている方向」と
    // 「ピクセル方向」が 90°/180° ずれる。MakeupRenderer は CGImage の
    // width/height でマスクを作るため、ここがズレるとメイクが顔の外に
    // 散らばって「画面全体が明るく/暗く」見える原因になる。
    //
    // パイプライン入口でこの関数を通し、以降は orientation=.up の画像だけを
    // 扱う前提にする。
    nonisolated func uprightOriented() -> UIImage {
        if imageOrientation == .up { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
