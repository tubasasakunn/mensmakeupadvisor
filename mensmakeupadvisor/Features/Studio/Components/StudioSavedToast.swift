import SwiftUI

// Look アーカイブ完了時に画面下部に表示する非永続トースト。
struct StudioSavedToast: View {
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                Text("保存しました")
                    .font(.system(size: 14, weight: .semibold))
                Text("·")
                    .opacity(0.5)
                Text("ホームの「保存」から開けます")
                    .font(.system(size: 12))
                    .opacity(0.8)
            }
            .foregroundStyle(Color.appBackground)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.ivory)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("保存しました。ホームの保存タブから開けます")
        .aid("studio_saved_notification")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}
