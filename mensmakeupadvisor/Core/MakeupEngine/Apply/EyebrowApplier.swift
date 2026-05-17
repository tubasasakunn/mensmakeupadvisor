import CoreGraphics
import Foundation
import UIKit

// 1.5 眉メイク
// makeup_claude/loadmap/1-virtual-makeup/1-5-eyebrow/main.py を移植。
//
//   Phase 1: 眉消し → `EyebrowEraser`
//   Phase 2: 眉描画 → `EyebrowDrawer`
nonisolated enum EyebrowApplier {
    nonisolated enum BrowType: String, CaseIterable, Sendable {
        case natural, straight, arch, parallel, corner
    }

    nonisolated struct Options: Sendable {
        var type: BrowType = .straight
        var colorRGB: SIMD3<Float> = SIMD3<Float>(85, 60, 45)
        var intensity: Float = 0.75
        var thicknessScale: Float = 1.0
        var doErase: Bool = true
        var doDraw: Bool = true
    }

    nonisolated static func apply(image: CGImage, faceMesh: FaceMesh, options: Options) -> CGImage? {
        var current = image
        if options.doErase, let erased = EyebrowEraser.erase(image: current, faceMesh: faceMesh) {
            current = erased
        }
        if options.doDraw, let drawn = EyebrowDrawer.draw(image: current, faceMesh: faceMesh, options: options) {
            current = drawn
        }
        return current
    }
}
