import SwiftUI

// 副ボタン。暗い panel 面 + ivory の薄い outline で「触れるが目立たせない」表現。
// (clear glass はフラットな暗背景の上だと効果が出ず崩れるため面塗りに統一)
// Primary を引き立てるための引き算デザイン。
struct GlassSecondaryButton: View {
    let title: String
    var icon: String? = nil
    let accessibilityID: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(Theme.Typography.UI.bodyRegular)
                }
                Text(title)
                    .font(Theme.Typography.UI.bodyMedium)
                    .kerning(0.3)
            }
            .foregroundStyle(Theme.Text.primarySoft)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Theme.Surface.panel, in: .capsule)
            .overlay(
                Capsule()
                    .stroke(Theme.Line.outlineIvorySoft, lineWidth: Theme.Size.Line.light)
            )
        }
        .buttonStyle(GlassPressedButtonStyle())
        .aid(accessibilityID)
    }
}

#Preview {
    ZStack {
        LuxeBackground()
        VStack(spacing: 20) {
            GlassSecondaryButton(
                title: "スキップ",
                accessibilityID: "preview_secondary"
            ) {}
            GlassSecondaryButton(
                title: "サンプル画像で試す",
                icon: "photo",
                accessibilityID: "preview_secondary_icon"
            ) {}
        }
        .padding(28)
    }
}
