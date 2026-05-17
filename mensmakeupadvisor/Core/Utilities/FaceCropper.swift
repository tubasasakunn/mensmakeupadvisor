import CoreGraphics
import UIKit

// 顔ランドマーク群を囲う bbox を求めて、その周辺で UIImage を切り抜くユーティリティ。
// MakeupEngineService.prepare の 1 段目で実行し、トリミング後の画像で再検出する
// ことで、Diagnosis / Studio / Tutorial すべての画面で「顔周辺だけ」が見える状態
// にする。
nonisolated enum FaceCropper {
    // landmarksPx: 検出後の 478 点のピクセル座標 (uprightOriented 後の画像基準)
    // image:        landmarksPx の基準になっている、向き正規化済み画像
    // paddingRatio: bbox 高さに対する上下左右パディング率 (0.25 で 25% ずつ)
    nonisolated static func crop(image: UIImage,
                                 landmarksPx: [CGPoint],
                                 paddingRatio: CGFloat = 0.28) -> UIImage? {
        guard !landmarksPx.isEmpty else { return nil }
        guard let cgImage = image.cgImage else { return nil }

        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)

        // 端点はノイズ的に外れることがあるので min/max ベースで OK。
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude
        for p in landmarksPx {
            if p.x < minX { minX = p.x }
            if p.y < minY { minY = p.y }
            if p.x > maxX { maxX = p.x }
            if p.y > maxY { maxY = p.y }
        }

        let bboxW = max(1, maxX - minX)
        let bboxH = max(1, maxY - minY)
        // 縦のほうが情報が多いので上は広め、下はやや狭めにとる。
        let padX = bboxW * paddingRatio
        let padTop = bboxH * (paddingRatio + 0.10)
        let padBottom = bboxH * paddingRatio

        var cropX = minX - padX
        var cropY = minY - padTop
        var cropW = bboxW + padX * 2
        var cropH = bboxH + padTop + padBottom

        // 画像内に収める
        if cropX < 0 { cropW += cropX; cropX = 0 }
        if cropY < 0 { cropH += cropY; cropY = 0 }
        if cropX + cropW > pixelWidth { cropW = pixelWidth - cropX }
        if cropY + cropH > pixelHeight { cropH = pixelHeight - cropY }
        guard cropW > 0, cropH > 0 else { return nil }

        // ほぼフルフレームの場合 (すでに顔アップ写真など) は切り出さずそのまま返す。
        let coverage = (cropW * cropH) / (pixelWidth * pixelHeight)
        if coverage > 0.92 { return image }

        let rect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH).integral
        guard let cropped = cgImage.cropping(to: rect) else { return nil }
        // uprightOriented したものを切り出しているので、orientation は .up で OK。
        return UIImage(cgImage: cropped, scale: image.scale, orientation: .up)
    }
}
