import SwiftUI

// Look アーカイブ完了時に画面下部に表示する非永続トースト。
// 保存完了の確認 UI。自動遷移はせず、ユーザーに「ホームへ」か「編集を続ける」かを
// 選んでもらう。アーカイブ直後にもう一度調整したいニーズを潰さないため。
struct StudioSavedToast: View {
    let onGoHome: () -> Void
    let onKeepEditing: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                    Text("保存しました")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                }
                Text("ホームの「保存」タブからいつでも開けます。")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Text.onAccentSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 10) {
                    Button(action: onKeepEditing) {
                        Text("編集を続ける")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.appBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .hairlineBorder(Theme.Line.onAccentSubtle)
                    }
                    .accessibilityLabel("編集を続ける")
                    .aid("studio_saved_keep_editing")

                    Button(action: onGoHome) {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("ホームへ")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color.ivory)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.appBackground)
                    }
                    .accessibilityLabel("ホームに戻る")
                    .aid("studio_saved_go_home")
                }
            }
            .foregroundStyle(Color.appBackground)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color.ivory)
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .accessibilityElement(children: .contain)
        .aid("studio_saved_notification")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}
