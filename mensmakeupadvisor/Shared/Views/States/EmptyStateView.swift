import SwiftUI

struct EmptyStateView: View {
    var icon: String = "♡"
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Text(icon)
                .font(.system(size: 56, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.inkTertiary)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.ivory)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(48)
        .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
        .accessibilityIdentifier("empty_state_view")
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        EmptyStateView(
            icon: "♡",
            title: "まだ保存されたルックがありません",
            message: "スタジオでルックを作成して保存してください"
        )
        .padding()
    }
}
