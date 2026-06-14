import Foundation

// OpenCV `cv2.distanceTransform` 相当。Felzenszwalb-Huttenlocher の
// 2-pass squared EDT を実装している。
nonisolated enum DistanceTransform {
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

        let scratch = FloatBuffer(width: max(w, h), height: 1)
        let v = UnsafeMutablePointer<Int>.allocate(capacity: max(w, h))
        let z = UnsafeMutablePointer<Float>.allocate(capacity: max(w, h) + 1)
        defer { v.deallocate(); z.deallocate() }

        for x in 0..<w {
            for y in 0..<h { scratch.pointer[y] = buf[x, y] }
            edt1d(scratch.pointer, n: h, v: v, z: z)
            for y in 0..<h { buf[x, y] = scratch.pointer[y] }
        }
        for y in 0..<h {
            for x in 0..<w { scratch.pointer[x] = buf[x, y] }
            edt1d(scratch.pointer, n: w, v: v, z: z)
            for x in 0..<w { buf[x, y] = scratch.pointer[x] }
        }

        for i in 0..<(w * h) {
            buf.pointer[i] = sqrtf(buf.pointer[i])
        }
        return buf
    }

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
            // inf を有限の 1e20 で近似しているため、参照実装が前提とする
            // 「z[0] = -∞ で必ず停止」が成り立たず k が負へ抜けうる。v/z は
            // UnsafeMutablePointer で境界チェックが無いので k > 0 を明示ガードする。
            while k > 0 && s <= z[k] {
                k -= 1
                s = ((f[q] + Float(q * q)) - (f[v[k]] + Float(v[k] * v[k])))
                    / Float(2 * q - 2 * v[k])
            }
            k += 1
            v[k] = q
            z[k] = s
            z[k + 1] = inf
        }
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
