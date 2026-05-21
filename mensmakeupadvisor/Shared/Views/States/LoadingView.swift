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
        .glassSurface(in: .rect(cornerRadius: Theme.Radius.lg))
        .aid("loading_view")
    }
}

#Preview {
    ZStack {
        LuxeBackground()
        LoadingView(message: "ANALYZING")
    }
}
