import CoreGraphics
import Foundation

// OpenCV BGR 順は使わず、Swift / CoreGraphics 標準の RGBA を使う。
// intensity と mask の積を α として、src を新色とブレンドする。
nonisolated enum Compositing {
    // 線形ブレンド (alpha_composite_normal)
    nonisolated static func normal(image: CGImage, mask: FloatBuffer,
                                   color: SIMD3<Float>, intensity: Float) -> CGImage? {
        // src は 0-1 に正規化済みなので color も 0-1 に揃える。
        // 揃えないと出力が極端に明るくなり、最終的に白飛びする。
        let cn = color / 255.0
        return applyBlend(image: image, mask: mask, intensity: intensity) { src, m in
            let r = src.x * (1 - m) + cn.x * m
            let g = src.y * (1 - m) + cn.y * m
            let b = src.z * (1 - m) + cn.z * m
            return SIMD3<Float>(r, g, b)
        }
    }

    // 明るい色を加算 (alpha_composite_additive)
    nonisolated static func additive(image: CGImage, mask: FloatBuffer,
                                     color: SIMD3<Float>, intensity: Float) -> CGImage? {
        return applyBlend(image: image, mask: mask, intensity: intensity) { src, m in
            let r = min(1.0, src.x + color.x * m / 255.0)
            let g = min(1.0, src.y + color.y * m / 255.0)
            let b = min(1.0, src.z + color.z * m / 255.0)
            return SIMD3<Float>(r, g, b)
        }
    }

    // 暗くする (alpha_composite_multiply, 影用)
    nonisolated static func multiply(image: CGImage, mask: FloatBuffer,
                                     color: SIMD3<Float>, intensity: Float) -> CGImage? {
        let cn = color / 255.0
        return applyBlend(image: image, mask: mask, intensity: intensity) { src, m in
            let r = src.x * (1 - m) + (src.x * cn.x) * m
            let g = src.y * (1 - m) + (src.y * cn.y) * m
            let b = src.z * (1 - m) + (src.z * cn.z) * m
            return SIMD3<Float>(r, g, b)
        }
    }

    private nonisolated static func applyBlend(
        image: CGImage,
        mask: FloatBuffer,
        intensity: Float,
        blend: (SIMD3<Float>, Float) -> SIMD3<Float>
    ) -> CGImage? {
        let w = image.width
        let h = image.height
        guard mask.width == w, mask.height == h else { return image }
        let bytesPerRow = w * 4
        let space = CGColorSpaceCreateDeviceRGB()
        let info: CGBitmapInfo = [
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            CGBitmapInfo.byteOrder32Big,
        ]

        let count = w * h * 4
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        defer { buffer.deallocate() }
        buffer.initialize(repeating: 0, count: count)

        guard let ctx = CGContext(
            data: buffer,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: space,
            bitmapInfo: info.rawValue
        ) else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

        for y in 0..<h {
            for x in 0..<w {
                let idx = (y * w + x) * 4
                let r = Float(buffer[idx]) / 255.0
                let g = Float(buffer[idx + 1]) / 255.0
                let b = Float(buffer[idx + 2]) / 255.0
                let m = mask[x, y] * intensity
                let out = blend(SIMD3<Float>(r, g, b), m)
                buffer[idx]     = UInt8(max(0, min(255, out.x * 255)))
                buffer[idx + 1] = UInt8(max(0, min(255, out.y * 255)))
                buffer[idx + 2] = UInt8(max(0, min(255, out.z * 255)))
                buffer[idx + 3] = 255
            }
        }
        return ctx.makeImage()
    }
}
