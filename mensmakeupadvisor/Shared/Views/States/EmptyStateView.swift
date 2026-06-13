import SwiftUI

// 状態が空の画面で使う再利用カード。Liquid Glass でホバー感を出す。
struct EmptyStateView: View {
    var icon: String = "♡"
    let title: String
    let message: String

    var body: some View {
        GlassCard(radius: Theme.Radius.xl, padding: Theme.Spacing.xxl) {
            VStack(spacing: Theme.Spacing.md) {
                Text(icon)
                    .font(Theme.Typography.Display.jumboLLight)
                    .italic()
                    .foregroundStyle(Theme.Text.secondary)
                Text(title)
                    .font(Theme.Typography.Display.headlineSemibold)
                    .italic()
                    .foregroundStyle(Color.ivory)
                Text(message)
                    .font(Theme.Typography.UI.subheadline)
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .frame(maxWidth: .infinity)
        }
        .aid("empty_state_view")
    }
}

#Preview {
    ZStack {
        LuxeBackground()
        EmptyStateView(
            icon: "♡",
            title: "まだ保存されたルックがありません",
            message: "スタジオでルックを作成して保存してください"
        )
        .padding()
    }
}
