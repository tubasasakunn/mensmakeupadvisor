import Accelerate
import CoreGraphics
import CoreImage
import Foundation
import UIKit

// makeup_claude の Python 実装で使われていた OpenCV 操作を CoreImage / Accelerate /
// 手書き実装で代替するユーティリティ集。
//
// - `cv2.fillPoly` → CGContext.fillPath（FaceMesh.buildMask）
// - `cv2.distanceTransform` → Felzenszwalb の2パススキャン (squared distance)
// - `cv2.GaussianBlur` → vImage Gaussian box approximation または手書き separable
// - `cv2.dilate` → 単純な morphological dilation
// - `cv2.inpaint TELEA` → 境界色の方向別サンプリングフィル (簡易版)
// - power curve → `pow` を要素ごとに適用
// - alpha blending → 単純な per-pixel 演算

// MARK: - Mask buffer (UInt8, single channel, value 0-255)

final class MaskBuffer {
    let width: Int
    let height: Int
    nonisolated(unsafe) private var storage: UnsafeMutableBufferPointer<UInt8>

    nonisolated init(width: Int, height: Int) {
        self.width = width
        self.height = height
        let raw = UnsafeMutableRawPointer.allocate(byteCount: width * height, alignment: 16)
        raw.initializeMemory(as: UInt8.self, repeating: 0, count: width * height)
        storage = UnsafeMutableBufferPointer(
            start: raw.assumingMemoryBound(to: UInt8.self),
            count: width * height
        )
    }

    deinit {
        UnsafeMutableRawPointer(storage.baseAddress!).deallocate()
    }

    nonisolated var dataPointer: UnsafeMutableRawPointer { UnsafeMutableRawPointer(storage.baseAddress!) }
    nonisolated var pointer: UnsafeMutablePointer<UInt8> { storage.baseAddress! }
    nonisolated var count: Int { width * height }

    nonisolated subscript(x: Int, y: Int) -> UInt8 {
        get { storage[y * width + x] }
        set { storage[y * width + x] = newValue }
    }
}

// MARK: - Float buffer (single channel, normalized 0-1)

final class FloatBuffer {
    let width: Int
    let height: Int
    nonisolated(unsafe) var storage: UnsafeMutableBufferPointer<Float>

    nonisolated init(width: Int, height: Int) {
        self.width = width
        self.height = height
        let raw = UnsafeMutableRawPointer.allocate(
            byteCount: width * height * MemoryLayout<Float>.stride,
            alignment: 16
        )
        raw.initializeMemory(as: Float.self, repeating: 0, count: width * height)
        storage = UnsafeMutableBufferPointer(
            start: raw.assumingMemoryBound(to: Float.self),
            count: width * height
        )
    }

    deinit {
        UnsafeMutableRawPointer(storage.baseAddress!).deallocate()
    }

    nonisolated var pointer: UnsafeMutablePointer<Float> { storage.baseAddress! }
    nonisolated var count: Int { width * height }

    nonisolated subscript(x: Int, y: Int) -> Float {
        get { storage[y * width + x] }
        set { storage[y * width + x] = newValue }
    }

    nonisolated static func fromMask(_ mask: MaskBuffer) -> FloatBuffer {
        let out = FloatBuffer(width: mask.width, height: mask.height)
        for i in 0..<out.count {
            out.pointer[i] = Float(mask.pointer[i]) / 255.0
        }
        return out
    }
}

// MARK: - Distance transform (squared, two-pass Felzenszwalb)

enum DistanceTransform {
    // 入力: foreground=true のマスク（値>0 を前景扱い）
    // 出力: 各画素から最近傍背景までの L2 距離（ピクセル単位）
    nonisolated static func l2(from mask: MaskBuffer) -> FloatBuffer {
        let w = mask.width
        let h = mask.height
        let inf: Float = 1e20

        // squared distance を計算するための入力 f
        let buf = FloatBuffer(width: w, height: h)
        for i in 0..<(w * h) {
            buf.pointer[i] = mask.pointer[i] > 0 ? inf : 0
        }

        // 1D squared EDT, columns then rows
        let scratch = FloatBuffer(width: max(w, h), height: 1)
        let v = UnsafeMutablePointer<Int>.allocate(capacity: max(w, h))
        let z = UnsafeMutablePointer<Float>.allocate(capacity: max(w, h) + 1)
        defer { v.deallocate(); z.deallocate() }

        // columns
        for x in 0..<w {
            // Read column
            for y in 0..<h { scratch.pointer[y] = buf[x, y] }
            edt1d(scratch.pointer, n: h, v: v, z: z)
            for y in 0..<h { buf[x, y] = scratch.pointer[y] }
        }
        // rows
        for y in 0..<h {
            for x in 0..<w { scratch.pointer[x] = buf[x, y] }
            edt1d(scratch.pointer, n: w, v: v, z: z)
            for x in 0..<w { buf[x, y] = scratch.pointer[x] }
        }

        // sqrt
        for i in 0..<(w * h) {
            buf.pointer[i] = sqrtf(buf.pointer[i])
        }
        return buf
    }

    // Felzenszwalb-Huttenlocher 1D squared distance transform
    private nonisolated static func edt1d(_ f: UnsafeMutablePointer<Float>, n: Int,
                              v: UnsafeMutablePointer<Int>,
                              z: UnsafeMutablePointer<Float>) {
        let inf: Float = 1e20
        var k = 0
        v[0] = 0
        z[0] = -inf
        z[1] = inf
        for q in 1..<n {
            var s = ((f[q] + Float(q * q)) - (f[v[k]] + Float(v[k] * v[k])))
                / Float(2 * q - 2 * v[k])
            while s <= z[k] {
                k -= 1
                s = ((f[q] + Float(q * q)) - (f[v[k]] + Float(v[k] * v[k])))
                    / Float(2 * q - 2 * v[k])
            }
            k += 1
            v[k] = q
            z[k] = s
            z[k + 1] = inf
        }
        // backup f
        let backup = UnsafeMutablePointer<Float>.allocate(capacity: n)
        defer { backup.deallocate() }
        for i in 0..<n { backup[i] = f[i] }

        var idx = 0
        for q in 0..<n {
            while z[idx + 1] < Float(q) { idx += 1 }
            let d = Float(q - v[idx])
            f[q] = d * d + backup[v[idx]]
        }
    }
}

// MARK: - Gaussian blur (separable, normalized kernel)

enum GaussianBlur {
    // 入力 FloatBuffer (0-1) を Gaussian で平滑化する。
    // OpenCV の `cv2.GaussianBlur(src, (k,k), sigma=k/3)` 相当。
    nonisolated static func apply(_ buffer: FloatBuffer, ksize: Int) {
        var k = max(3, ksize)
        if k.isMultiple(of: 2) { k += 1 }
        let sigma = Float(k) / 3.0

        let kernel = makeKernel(size: k, sigma: sigma)
        let half = k / 2
        let w = buffer.width
        let h = buffer.height

        let temp = FloatBuffer(width: w, height: h)

        // Horizontal pass
        for y in 0..<h {
            for x in 0..<w {
                var sum: Float = 0
                for i in -half...half {
                    let xi = min(max(x + i, 0), w - 1)
                    sum += buffer[xi, y] * kernel[i + half]
                }
                temp[x, y] = sum
            }
        }
        // Vertical pass
        for y in 0..<h {
            for x in 0..<w {
                var sum: Float = 0
                for i in -half...half {
                    let yi = min(max(y + i, 0), h - 1)
                    sum += temp[x, yi] * kernel[i + half]
                }
                buffer[x, y] = sum
            }
        }
    }

    private nonisolated static func makeKernel(size: Int, sigma: Float) -> [Float] {
        let half = Float(size / 2)
        var kernel = [Float](repeating: 0, count: size)
        var sum: Float = 0
        for i in 0..<size {
            let x = Float(i) - half
            let v = expf(-(x * x) / (2 * sigma * sigma))
            kernel[i] = v
            sum += v
        }
        for i in 0..<size { kernel[i] /= sum }
        return kernel
    }
}

// MARK: - Power curve

enum PowerCurve {
    nonisolated static func apply(_ buffer: FloatBuffer, exponent: Float) {
        for i in 0..<buffer.count {
            buffer.pointer[i] = powf(max(0, buffer.pointer[i]), exponent)
        }
    }
}

// MARK: - Normalize 0-1

enum BufferNormalize {
    nonisolated static func toUnit(_ buffer: FloatBuffer) {
        var mx: Float = 0
        for i in 0..<buffer.count { mx = max(mx, buffer.pointer[i]) }
        guard mx > 1e-6 else { return }
        let inv = 1.0 / mx
        for i in 0..<buffer.count { buffer.pointer[i] *= inv }
    }

    // mask * buffer の要素積（その範囲内に制限）
    nonisolated static func multiply(_ buffer: FloatBuffer, with mask: FloatBuffer) {
        for i in 0..<buffer.count {
            buffer.pointer[i] *= mask.pointer[i]
        }
    }

    // 1.0 - value （マスク領域内で反転）
    nonisolated static func invertWithin(_ buffer: FloatBuffer, mask: FloatBuffer) {
        for i in 0..<buffer.count {
            buffer.pointer[i] = (1.0 - buffer.pointer[i]) * mask.pointer[i]
        }
    }
}

// MARK: - Morphological dilate

enum Morphology {
    // 円形カーネルによる単純なグレースケール膨張。
    // OpenCV の `cv2.dilate(..., MORPH_ELLIPSE)` を粗く近似する。
    nonisolated static func dilate(_ buffer: FloatBuffer, radius: Int) {
        guard radius > 0 else { return }
        let w = buffer.width
        let h = buffer.height
        let copy = FloatBuffer(width: w, height: h)
        for i in 0..<buffer.count { copy.pointer[i] = buffer.pointer[i] }

        let r2 = radius * radius
        for y in 0..<h {
            for x in 0..<w {
                var maxV = copy[x, y]
                for dy in -radius...radius {
                    let yy = y + dy
                    if yy < 0 || yy >= h { continue }
                    for dx in -radius...radius {
                        if dx * dx + dy * dy > r2 { continue }
                        let xx = x + dx
                        if xx < 0 || xx >= w { continue }
                        let v = copy[xx, yy]
                        if v > maxV { maxV = v }
                    }
                }
                buffer[x, y] = maxV
            }
        }
    }
}

// MARK: - Compositing

enum Compositing {
    // OpenCV BGR 順は使わず、Swift / CoreGraphics 標準の RGBA を使う。
    // intensity と mask の積を α として、src を新色とブレンドする。

    // alpha_composite_normal: 線形ブレンド
    nonisolated static func normal(image: CGImage, mask: FloatBuffer,
                       color: SIMD3<Float>, intensity: Float) -> CGImage? {
        return applyBlend(image: image, mask: mask, intensity: intensity) { src, m in
            let r = src.x * (1 - m) + color.x * m
            let g = src.y * (1 - m) + color.y * m
            let b = src.z * (1 - m) + color.z * m
            return SIMD3<Float>(r, g, b)
        }
    }

    // alpha_composite_additive: 明るい色を加算
    nonisolated static func additive(image: CGImage, mask: FloatBuffer,
                         color: SIMD3<Float>, intensity: Float) -> CGImage? {
        return applyBlend(image: image, mask: mask, intensity: intensity) { src, m in
            let r = min(1.0, src.x + color.x * m / 255.0)
            let g = min(1.0, src.y + color.y * m / 255.0)
            let b = min(1.0, src.z + color.z * m / 255.0)
            return SIMD3<Float>(r, g, b)
        }
    }

    // alpha_composite_multiply: 暗くする（影）
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

    // 共通ベース: マスク・強度をかけたα、ピクセル単位の関数（color は 0-255 で渡す）
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

// MARK: - UIImage / CGImage helpers

extension UIImage {
    var safeCGImage: CGImage? {
        if let img = cgImage { return img }
        guard let ci = ciImage else { return nil }
        let ctx = CIContext(options: nil)
        return ctx.createCGImage(ci, from: ci.extent)
    }
}
