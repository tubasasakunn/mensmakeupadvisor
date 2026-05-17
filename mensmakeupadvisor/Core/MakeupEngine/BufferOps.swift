import Foundation

// FloatBuffer に対する要素単位の演算ユーティリティ群。
// makeup_claude の Python 実装で numpy の broadcast 演算として書かれていた処理を
// それぞれ namespace 化している。

nonisolated enum PowerCurve {
    nonisolated static func apply(_ buffer: FloatBuffer, exponent: Float) {
        for i in 0..<buffer.count {
            buffer.pointer[i] = powf(max(0, buffer.pointer[i]), exponent)
        }
    }
}

nonisolated enum BufferNormalize {
    nonisolated static func toUnit(_ buffer: FloatBuffer) {
        var mx: Float = 0
        for i in 0..<buffer.count { mx = max(mx, buffer.pointer[i]) }
        guard mx > 1e-6 else { return }
        let inv = 1.0 / mx
        for i in 0..<buffer.count { buffer.pointer[i] *= inv }
    }

    nonisolated static func multiply(_ buffer: FloatBuffer, with mask: FloatBuffer) {
        for i in 0..<buffer.count {
            buffer.pointer[i] *= mask.pointer[i]
        }
    }

    nonisolated static func invertWithin(_ buffer: FloatBuffer, mask: FloatBuffer) {
        for i in 0..<buffer.count {
            buffer.pointer[i] = (1.0 - buffer.pointer[i]) * mask.pointer[i]
        }
    }
}

// OpenCV `cv2.dilate(..., MORPH_ELLIPSE)` を粗く近似する円形カーネル膨張。
nonisolated enum Morphology {
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
