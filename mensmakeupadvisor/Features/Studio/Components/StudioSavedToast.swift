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
            GlassPanel(radius: Theme.Radius.xl, padding: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.ivory)
                        Text("保存しました")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .italic()
                            .foregroundStyle(Color.ivory)
                        Spacer()
                    }
                    Text("ホームの「保存」タブからいつでも開けます。")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Text.primaryFaded)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: Theme.Spacing.md) {
                        // GlassPanel の中なので glass を重ねず、輪郭線だけの
                        // セカンダリボタンにする (glass-on-glass 回避)。
                        keepEditingButton
                        GlassPrimaryButton(
                            title: "ホームへ",
                            icon: "house.fill",
                            showsTrailingChevron: false,
                            accessibilityID: "studio_saved_go_home"
                        ) {
                            Haptics.soft()
                            onGoHome()
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, 100)
        }
        .accessibilityElement(children: .contain)
        .aid("studio_saved_notification")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // glass を持たない輪郭線ボタン。GlassPanel の内側で使う前提。
    private var keepEditingButton: some View {
        Button {
            Haptics.soft()
            onKeepEditing()
        } label: {
            Text("編集を続ける")
                .font(.system(size: 14, weight: .medium))
                .kerning(0.3)
                .foregroundStyle(Theme.Text.primarySoft)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .overlay(
                    Capsule().strokeBorder(Theme.Line.outlineIvorySoft, lineWidth: 0.6)
                )
        }
        .buttonStyle(GlassPressedButtonStyle())
        .aid("studio_saved_keep_editing")
    }
}
