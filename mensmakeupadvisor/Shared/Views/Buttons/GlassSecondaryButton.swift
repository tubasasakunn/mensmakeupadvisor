import SwiftUI

struct GlassSecondaryButton: View {
    let title: String
    let accessibilityID: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .overlay(Capsule().stroke(Theme.Diagram.jawLine, lineWidth: 1))
                .foregroundStyle(Color.ivory)
        }
        .aid(accessibilityID)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        GlassSecondaryButton(
            title: "スキップ",
            accessibilityID: "preview_secondary_button"
        ) {}
    }
}
