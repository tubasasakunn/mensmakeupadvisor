import SwiftUI

// コンテンツ容器・チップ・操作ボタンの共通ラッパー群。
// 角丸スケール・余白・hairline 補強の規約を 1 箇所に集約する。
//
// Liquid Glass の使い分け (Apple HIG):
//   - Liquid Glass は「コンテンツの上に浮かぶナビゲーション/操作層」専用。
//     ツールバー・タブバー・フローティングボタン・操作コントロールに使う。
//   - コンテンツ層 (カード・パネル・リスト・背景) にはガラスを使わない。
//     不透明な面 (Theme.Surface.card) にして階層を明確にする。
//   - ガラスの上にガラスを重ねない。
//
// そのため GlassCard / GlassPanel はコンテンツ容器として「不透明」。
// ガラスは GlassIconButton や各画面の操作チップなど操作層だけに残す。

// MARK: - GlassCard (コンテンツカード — 不透明)

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
                // active state などで薄い色を乗せたい場合の tint。
                if let tint {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(tint.opacity(0.22))
                }
            }
            .background {
                // コンテンツ層なので不透明な面にする (ガラスは使わない)。
                RoundedRectangle(cornerRadius: radius)
                    .fill(Theme.Surface.card)
            }
            .overlay(
                // 輪郭を ivory で 1px 強調して面を引き締める。
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Theme.Line.outlineIvorySoft, lineWidth: 0.5)
            )
    }
}

// MARK: - GlassPanel (大型コンテンツコンテナ — 不透明)

struct GlassPanel<Content: View>: View {
    var radius: CGFloat = Theme.Radius.xl
    var padding: CGFloat = Theme.Spacing.xl
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Theme.Surface.card)
            }
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Theme.Line.outlineIvorySoft, lineWidth: 0.5)
            )
    }
}

// MARK: - GlassPill (小さいチップ・ラベル — 不透明)

// 非操作のラベル/バッジはオーバーレイ層。ガラスではなく不透明な
// ラベル面 (labelBackdrop) を使う。
struct GlassPill<Content: View>: View {
    var hPadding: CGFloat = Theme.Spacing.md
    var vPadding: CGFloat = Theme.Spacing.sm
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
            .background { Capsule().fill(Theme.Surface.labelBackdrop) }
    }
}

// MARK: - GlassIconButton (丸いアイコンボタン — 操作層なのでガラス)

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
        .glassEffect(.regular, in: .circle)
        .accessibilityLabel(accessibilityLabel ?? systemImage)
        .aid(accessibilityID)
    }
}

// MARK: - GlassDivider (不透明面の上で使う極薄ライン)

struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Line.outlineIvorySoft)
            .frame(height: 1)
    }
}
