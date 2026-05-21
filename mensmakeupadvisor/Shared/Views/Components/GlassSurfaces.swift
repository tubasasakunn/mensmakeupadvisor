import SwiftUI

// iOS 26 Liquid Glass の標準的な見た目を提供するラッパー群。
// 直接 `.glassEffect(...)` を書き散らさず、これらを使うことで
// 角丸スケール・余白・hairline 補強の規約を 1 箇所に集約する。
//
// 配置のルール:
//   - Glass の上に Glass を重ねない (CLAUDE.md 違反になる)
//   - 必ず LuxeBackground のような有彩な背景の上に置く
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
                // tint を入れて欲しい場合 (active state など) のために
                // 1 枚薄い色を下敷きにできる。角丸は下地と揃える。
                if let tint {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(tint.opacity(0.22))
                }
            }
            .glassSurface(in: .rect(cornerRadius: radius))
            .overlay(
                // ガラスの輪郭を ivory で 1px 強調すると luxury 感が出る。
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Theme.Line.outlineIvorySoft, lineWidth: 0.5)
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
            .glassSurface(in: .rect(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Theme.Line.outlineIvorySoft, lineWidth: 0.5)
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
            .glassSurface(in: .capsule)
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
        .glassSurface(in: .circle)
        .accessibilityLabel(accessibilityLabel ?? systemImage)
        .aid(accessibilityID)
    }
}

// MARK: - glassSurface (暗いテーマに馴染む regular glass)

extension View {
    // `.glassEffect(.regular, in:)` の下に暗い下地を 1 枚敷くヘルパ。
    // 暗背景の上でガラスが明るいグレーとして浮くのを抑え、
    // ivory テキストのコントラストを確保する。regular glass を使う
    // パネル・チップ・丸ボタンはすべてこれを通すこと。
    func glassSurface(in shape: some Shape) -> some View {
        background { shape.fill(Theme.Surface.glassUnderlay) }
            .glassEffect(.regular, in: shape)
    }
}

// MARK: - GlassDivider (ガラス上で使う極薄ライン)

// HairlineDivider は不透明背景向けだが、ガラス上では ivory ベースで
// もう少し明るくないとなじまない。
struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Line.outlineIvorySoft)
            .frame(height: 1)
    }
}
