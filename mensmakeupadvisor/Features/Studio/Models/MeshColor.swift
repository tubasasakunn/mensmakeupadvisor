import Foundation

// 1メッシュに乗る化粧の色。RGB は 0–255、alpha は 0–1 (= 強度)。
// alpha=0 は「その化粧がそのメッシュに乗っていない」を意味する。
nonisolated struct MeshColor: Sendable, Hashable {
    var r: Float
    var g: Float
    var b: Float
    var a: Float

    static let clear = MeshColor(r: 0, g: 0, b: 0, a: 0)

    var isVisible: Bool { a > 0 }

    // Applier に渡す RGB ベクトル (0–255)。
    var simd: SIMD3<Float> { SIMD3<Float>(r, g, b) }

    // self を base の上に source-over 合成した色。
    // 複数の化粧を同じメッシュに重ねた「合計した色」を求めるのに使う。
    func composited(over base: MeshColor) -> MeshColor {
        guard a > 0 else { return base }
        let outA = a + base.a * (1 - a)
        guard outA > 0 else { return .clear }
        func channel(_ src: Float, _ dst: Float) -> Float {
            (src * a + dst * base.a * (1 - a)) / outA
        }
        return MeshColor(
            r: channel(r, base.r),
            g: channel(g, base.g),
            b: channel(b, base.b),
            a: outA
        )
    }

    // 強度 (0–1) だけ差し替えたコピー。
    func withIntensity(_ intensity: Float) -> MeshColor {
        MeshColor(r: r, g: g, b: b, a: max(0, min(1, intensity)))
    }
}
