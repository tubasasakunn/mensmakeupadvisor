import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.ivory)
                .scaleEffect(1.5)
            Text(message)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
        }
        .accessibilityIdentifier("loading_view")
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        LoadingView(message: "分析中...")
    }
}
