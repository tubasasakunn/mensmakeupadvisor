import SwiftUI

// アプリの主要 CTA。Liquid Glass の capsule + bordeaux 着色 + chevron で
// 「次に進めるのはここ」と一瞬で分かる重みを持たせる。
//
// 設計:
//   - 背景: bordeaux のソフトな下敷き → 上から glassEffect でルミナンスを乗せる
//   - tint: ivory のテキスト。近接でも読みやすいよう sans semibold
//   - icon は左、arrow は右に既定で挿入される (showsTrailingChevron で抑制可)
//   - 押下時は scale で軽い触覚フィードバック (Reduce Motion 対応)
struct GlassPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var showsTrailingChevron: Bool = true
    let accessibilityID: String
    var isProminent: Bool = true   // false でアクセントなし (ivory 透明)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .kerning(0.3)
                Spacer(minLength: 0)
                if showsTrailingChevron {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .opacity(0.85)
                }
            }
            .foregroundStyle(Color.ivory)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background {
                // bordeaux の発光下敷きは必ず capsule で切り抜く。
                // .background(LinearGradient) だと矩形のままになり、
                // capsule の角の外に赤がはみ出して「丸ボタンなのに背景も赤い」
                // 見た目になっていた。Capsule().fill で形状にクリップする。
                if isProminent {
                    Capsule().fill(
                        LinearGradient(
                            colors: [
                                Theme.Accent.primarySoft,
                                Theme.Accent.primarySubtle
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
            .glassEffect(.regular, in: .capsule)
            .overlay(
                // ハイライトのリム — ガラスの上端を ivory で薄く光らせる
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.Line.outlineIvory,
                                Theme.Line.outlineIvorySoft.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.6
                    )
            )
        }
        .buttonStyle(GlassPressedButtonStyle())
        .aid(accessibilityID)
    }
}

// 押下時に軽く縮める ButtonStyle。Reduce Motion を尊重する。
struct GlassPressedButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .animation(Theme.Motion.quick, value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        LuxeBackground()
        VStack(spacing: 20) {
            GlassPrimaryButton(
                title: "撮影をはじめる",
                icon: "camera.fill",
                accessibilityID: "preview_primary_button"
            ) {}
            GlassPrimaryButton(
                title: "次へ",
                showsTrailingChevron: false,
                accessibilityID: "preview_primary_button_no_chev"
            ) {}
            GlassPrimaryButton(
                title: "ホームに戻る",
                accessibilityID: "preview_primary_neutral",
                isProminent: false
            ) {}
        }
        .padding(28)
    }
}
