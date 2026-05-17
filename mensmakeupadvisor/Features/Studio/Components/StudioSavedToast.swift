import SwiftUI

// Look アーカイブ完了時に画面下部に表示する非永続トースト。
struct StudioSavedToast: View {
    var body: some View {
        VStack {
            Spacer()
            Text("✓ LOOK ARCHIVED")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.appBackground)
                .kerning(2)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.ivory)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 100)
        }
        .aid("studio_saved_notification")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}
