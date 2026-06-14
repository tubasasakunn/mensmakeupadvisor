import SwiftUI

// アプリの主要 CTA。bordeaux のソリッドな capsule で「ここを押す」を
// 一義に示す。Liquid Glass のガラス感は背景・カード側に任せ、
// プライマリ CTA 自体はノイズを排した単色面に統一する。
//
// 設計:
//   - 背景: bordeaux の単色。グラデーション縞や半透明レイヤは入れない
//     (重ねるほど赤の濃淡が増えて「赤の上に赤い枠」のように見えるため)
//   - 内側上端の極薄ハイライトのみで「ガラスのリフト感」を残す
//     (ivory の輪郭は塗りと喧嘩するので削除)
//   - 影: bordeaux のソフトな発光。背景から自然に浮き上がらせる
//   - tint: ivory のテキスト。近接でも読みやすいよう sans semibold
//   - 押下時は scale で軽い触覚フィードバック (Reduce Motion 対応)
struct GlassPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var showsTrailingChevron: Bool = true
    let accessibilityID: String
    var isProminent: Bool = true   // false でアクセントなし (clear glass + 薄い outline)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(Theme.Typography.UI.bodyLargeSemibold)
                }
                Text(title)
                    .font(Theme.Typography.UI.bodyLargeSemibold)
                    .kerning(0.3)
                Spacer(minLength: 0)
                if showsTrailingChevron {
                    Image(systemName: "arrow.right")
                        .font(Theme.Typography.UI.calloutSemibold)
                        .opacity(0.85)
                }
            }
            .foregroundStyle(Color.ivory)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .modifier(GlassPrimaryButtonSurface(isProminent: isProminent))
        }
        .buttonStyle(GlassPressedButtonStyle())
        .aid(accessibilityID)
    }
}

// プライマリ CTA の塗り・縁・影をまとめた surface modifier。
// DiagnosisView の二段組 CTA など、ボタン構造が違うが同じ見た目で
// 統一したい場面でも再利用できるように切り出している。
struct GlassPrimaryButtonSurface: ViewModifier {
    let isProminent: Bool

    func body(content: Content) -> some View {
        if isProminent {
            content
                .background(Capsule().fill(Theme.Accent.primary))
                .overlay(
                    // 上端の極薄ハイライトだけ。下半分は塗りに溶け込ませる。
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: Theme.Size.Line.light
                        )
                )
                .shadow(color: Theme.Accent.primary.opacity(0.28), radius: 18, x: 0, y: 6)
        } else {
            content
                .glassEffect(.clear, in: .capsule)
                .overlay(
                    Capsule()
                        .strokeBorder(Theme.Line.outlineIvorySoft, lineWidth: Theme.Size.Line.light)
                )
        }
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
        VStack(spacing: Theme.Spacing.xl) {
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
        .padding(Theme.Spacing.xxl)
    }
}
