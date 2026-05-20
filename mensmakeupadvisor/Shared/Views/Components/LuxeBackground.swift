import SwiftUI

// アプリ全体の背景。
// Liquid Glass は「向こうに何かがある」ことで初めて活きるので、
// canvas 単色ではなく暖色のオーブ 2 つを ambient gradient にした上に
// 微細グレインを乗せて奥行きを作る。
//
// 使い方:
//   ZStack { LuxeBackground(); ... 画面の中身 ... }
//
// パラメータ:
//   - intensity: orb の濃さ。0.0 でほぼ単色、1.0 でオーブが目立つ。既定 0.6。
//   - warmOrbAlignment / coolOrbAlignment: オーブの位置をずらしたいときに。
struct LuxeBackground: View {
    var intensity: Double = 0.6
    var warmOrbAlignment: UnitPoint = .init(x: 0.85, y: 0.12)
    var coolOrbAlignment: UnitPoint = .init(x: 0.15, y: 0.92)

    var body: some View {
        ZStack {
            // ── 1. ベースのキャンバス。中心は canvas、周縁に向かって canvasDeep
            RadialGradient(
                colors: [Theme.Ambient.backdrop, Theme.Ambient.backdropDeep],
                center: .center,
                startRadius: 0,
                endRadius: 700
            )

            // ── 2. 暖色オーブ (右上) — bordeaux の柔らかい光
            RadialGradient(
                colors: [Theme.Ambient.orbWarm.opacity(intensity), .clear],
                center: warmOrbAlignment,
                startRadius: 0,
                endRadius: 380
            )
            .blendMode(.plusLighter)
            .allowsHitTesting(false)

            // ── 3. 冷色オーブ (左下) — sulphur の遠い反射
            RadialGradient(
                colors: [Theme.Ambient.orbCool.opacity(intensity * 0.7), .clear],
                center: coolOrbAlignment,
                startRadius: 0,
                endRadius: 460
            )
            .blendMode(.plusLighter)
            .allowsHitTesting(false)

            // ── 4. 微細グレイン (フィルム的なテクスチャ)
            LuxeFilmGrain()
                .opacity(0.4)
                .allowsHitTesting(false)
                .blendMode(.overlay)

            // ── 5. 外周ビネット (高級感の "額装")
            RadialGradient(
                colors: [.clear, Theme.Ambient.vignette.opacity(0.5)],
                center: .center,
                startRadius: 320,
                endRadius: 720
            )
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

// Canvas で疑似的な film grain を描く。実行時生成なのでアセット不要。
private struct LuxeFilmGrain: View {
    var body: some View {
        Canvas { context, size in
            // 決定論的にする — ランダムだとフレーム毎にチラつく。
            var seed: UInt64 = 0x9E3779B97F4A7C15
            func next() -> Double {
                seed &+= 0x9E3779B97F4A7C15
                var z = seed
                z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
                z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
                z = z ^ (z >> 31)
                return Double(z % 1000) / 1000.0
            }

            let dotCount = Int(size.width * size.height / 2200)
            for _ in 0..<dotCount {
                let x = next() * size.width
                let y = next() * size.height
                let alpha = 0.04 + next() * 0.06
                let r = 0.4 + next() * 0.6
                let rect = CGRect(x: x, y: y, width: r, height: r)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(alpha))
                )
            }
        }
    }
}

#Preview {
    LuxeBackground()
}
