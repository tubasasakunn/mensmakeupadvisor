import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .tint(Color.ivory)
                .scaleEffect(1.4)
            Text(message)
                .font(Theme.Typography.Data.baseRegular)
                .kerning(2)
                .foregroundStyle(Theme.Text.primaryFaded)
        }
        .padding(Theme.Spacing.xxl)
        .background(Theme.Surface.panel, in: .rect(cornerRadius: Theme.Radius.lg))
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
