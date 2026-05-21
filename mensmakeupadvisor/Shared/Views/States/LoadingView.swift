import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .tint(Color.ivory)
                .scaleEffect(1.4)
            Text(message)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .kerning(2)
                .foregroundStyle(Theme.Text.primaryFaded)
        }
        .padding(Theme.Spacing.xxl)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Surface.card)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(Theme.Line.outlineIvorySoft, lineWidth: 0.5)
        )
        .aid("loading_view")
    }
}

#Preview {
    ZStack {
        LuxeBackground()
        LoadingView(message: "ANALYZING")
    }
}
