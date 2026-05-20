import SwiftUI

// Studio 画面下部のアーカイブ + シェアボタン。シェア時のレンダリング進捗を
// 自身で持つことで、StudioView 本体が UI 状態を直接抱えなくて済む。
struct StudioBottomBar: View {
    @Environment(AppState.self) private var appState
    let onArchive: () -> Void
    @State private var isRenderingShare = false

    var body: some View {
        HStack(spacing: 10) {
            archiveButton
            shareButton.frame(width: 52)
        }
    }

    private var archiveButton: some View {
        Button(action: onArchive) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                Text("このルックを保存")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(Color.ivory)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                Rectangle().stroke(Color.lineStrong, lineWidth: 1)
            )
        }
        .accessibilityLabel("このルックを保存")
        .aid("studio_save_button")
    }

    private var shareButton: some View {
        Button {
            Task { await shareCurrentLook() }
        } label: {
            Group {
                if isRenderingShare {
                    ProgressView()
                        .tint(Color.inkSecondary)
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.ivory)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(Rectangle().stroke(Color.lineStrong, lineWidth: 1))
        }
        .accessibilityLabel(isRenderingShare ? "シェア画像を準備中" : "シェアする")
        .aid("studio_share_button")
        .disabled(isRenderingShare)
    }

    private func shareCurrentLook() async {
        guard let result = appState.analysisResult else { return }
        isRenderingShare = true
        defer { isRenderingShare = false }
        let card = DiagnosisShareCardView(result: result)
        if let image = ShareHelper.render(card) {
            ShareHelper.present([image])
        }
    }
}
