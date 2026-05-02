import SwiftUI

struct GlassPrimaryButton: View {
    let title: String
    var icon: String? = nil
    let accessibilityID: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .foregroundStyle(Color.ivory)
        }
        .glassEffect(.regular, in: .capsule)
        .accessibilityIdentifier(accessibilityID)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            GlassPrimaryButton(
                title: "分析する",
                icon: "wand.and.stars",
                accessibilityID: "preview_primary_button"
            ) {}
            GlassPrimaryButton(
                title: "次へ",
                accessibilityID: "preview_primary_button_no_icon"
            ) {}
        }
    }
}
