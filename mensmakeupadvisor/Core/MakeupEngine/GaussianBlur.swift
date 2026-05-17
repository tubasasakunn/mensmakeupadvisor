import Accelerate
import Foundation

// OpenCV `cv2.GaussianBlur(src, (k,k), sigma=k/3)` の代替。
// vDSP_conv で行・列方向に separable convolution を行う。
nonisolated enum GaussianBlur {
    nonisolated static func apply(_ buffer: FloatBuffer, ksize: Int) {
        var k = max(3, ksize)
        if k.isMultiple(of: 2) { k += 1 }
        let sigma = Float(k) / 3.0

        let kernel = makeKernel(size: k, sigma: sigma)
        let half = k / 2
        let w = buffer.width
        let h = buffer.height

        let temp = FloatBuffer(width: w, height: h)
        let stride = vDSP_Stride(1)

        // ─── Horizontal pass: 各行を端折り返しで pad → 1D 畳み込み
        var padded = [Float](repeating: 0, count: w + 2 * half)
        for y in 0..<h {
            let rowBase = buffer.pointer.advanced(by: y * w)
            let left = rowBase[0]
            for i in 0..<half { padded[i] = left }
            padded.withUnsafeMutableBufferPointer { dst in
                for x in 0..<w { dst[x + half] = rowBase[x] }
            }
            let right = rowBase[w - 1]
            for i in 0..<half { padded[w + half + i] = right }
            let tempRow = temp.pointer.advanced(by: y * w)
            padded.withUnsafeBufferPointer { src in
                kernel.withUnsafeBufferPointer { kp in
                    vDSP_conv(src.baseAddress!, stride,
                              kp.baseAddress!, stride,
                              tempRow, stride,
                              vDSP_Length(w), vDSP_Length(k))
                }
            }
        }

        // ─── Vertical pass: 列を抜き出して同様に conv → 戻す
        var col = [Float](repeating: 0, count: h)
        var paddedCol = [Float](repeating: 0, count: h + 2 * half)
        var resultCol = [Float](repeating: 0, count: h)
        for x in 0..<w {
            for y in 0..<h { col[y] = temp.pointer[y * w + x] }
            let top = col[0]
            for i in 0..<half { paddedCol[i] = top }
            for y in 0..<h { paddedCol[y + half] = col[y] }
            let bot = col[h - 1]
            for i in 0..<half { paddedCol[h + half + i] = bot }
            paddedCol.withUnsafeBufferPointer { src in
                kernel.withUnsafeBufferPointer { kp in
                    resultCol.withUnsafeMutableBufferPointer { dst in
                        vDSP_conv(src.baseAddress!, stride,
                                  kp.baseAddress!, stride,
                                  dst.baseAddress!, stride,
                                  vDSP_Length(h), vDSP_Length(k))
                    }
                }
            }
            for y in 0..<h { buffer.pointer[y * w + x] = resultCol[y] }
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
