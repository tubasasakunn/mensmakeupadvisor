import SwiftUI

// カード・パネル・チップ・丸ボタンの面を提供するラッパー群。
// 角丸スケール・余白・hairline 補強の規約を 1 箇所に集約する。
//
// なぜ system glass (.glassEffect(.regular)) を使わないか:
//   Liquid Glass の .regular は背後に色味のあるコンテンツがある前提のマテリアル。
//   本アプリの LuxeBackground はオーブの届かない領域が低彩度の暗部になり、
//   その上に .regular を重ねると白く曇って「板」に見えてしまう
//   (CLAUDE.md「単色/薄い背景の上で glass は崩れる」)。
//   そのため面は Theme.Surface.panel (暗い ivory 半透明) + ivory hairline で表現する。
//
// 配置のルール:
//   - 必ず LuxeBackground の上に置く (面が透けて奥行きが出る)
//   - テキストは .primary / .ivory / Theme.Text.primarySoft を使い、可読性を担保

// MARK: - GlassCard (汎用カード)

struct GlassCard<Content: View>: View {
    var radius: CGFloat = Theme.Radius.lg
    var padding: CGFloat = Theme.Spacing.xl
    var tint: Color? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                // 暗い面 (panel) を基調に、active state 等では tint を重ねる。
                ZStack {
                    Theme.Surface.panel
                    if let tint {
                        tint.opacity(0.22)
                    }
                }
                .clipShape(.rect(cornerRadius: radius))
            }
            .overlay(
                // 面の輪郭を ivory で 1px 強調すると luxury 感が出る。
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Theme.Line.outlineIvorySoft, lineWidth: Theme.Size.Line.thin)
            )
    }
}

// MARK: - GlassPanel (大型コンテナ、controls 全体を載せる用)

struct GlassPanel<Content: View>: View {
    var radius: CGFloat = Theme.Radius.xl
    var padding: CGFloat = Theme.Spacing.xl
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Surface.panel, in: .rect(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Theme.Line.outlineIvorySoft, lineWidth: Theme.Size.Line.thin)
            )
    }
}

// MARK: - GlassPill (小さいチップ・ラベル)

struct GlassPill<Content: View>: View {
    var hPadding: CGFloat = Theme.Spacing.md
    var vPadding: CGFloat = Theme.Spacing.sm
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
            .background(Theme.Surface.panelRaised, in: .capsule)
            .overlay(
                Capsule().stroke(Theme.Line.outlineIvorySoft, lineWidth: 0.5)
            )
    }
}

// MARK: - GlassIconButton (丸いアイコンボタン)

struct GlassIconButton: View {
    let systemImage: String
    let accessibilityID: String
    var accessibilityLabel: String? = nil
    var size: CGFloat = 44
    var iconSize: CGFloat = 17
    var iconWeight: Font.Weight = .medium
    var tint: Color = Theme.Text.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: iconWeight))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
        }
        .background(Theme.Surface.panelRaised, in: .circle)
        .overlay(
            Circle().stroke(Theme.Line.outlineIvorySoft, lineWidth: 0.5)
        )
        .accessibilityLabel(accessibilityLabel ?? systemImage)
        .aid(accessibilityID)
    }
}

// MARK: - GlassDivider (ガラス上で使う極薄ライン)

// HairlineDivider は不透明背景向けだが、ガラス上では ivory ベースで
// もう少し明るくないとなじまない。
struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Line.outlineIvorySoft)
            .frame(height: Theme.Size.Stroke.hairline)
    }
}
