import SwiftUI

// Studio 画面下部のアーカイブ + シェアボタン。シェア時のレンダリング進捗を
// 自身で持つことで、StudioView 本体が UI 状態を直接抱えなくて済む。
struct StudioBottomBar: View {
    @Environment(AppState.self) private var appState
    let onArchive: () -> Void
    @State private var isRenderingShare = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            archiveButton
            shareButton.frame(width: 56)
        }
    }

    private var archiveButton: some View {
        GlassPrimaryButton(
            title: "このルックを保存",
            icon: "heart.fill",
            showsTrailingChevron: false,
            accessibilityID: "studio_save_button",
            isProminent: true,
            action: onArchive
        )
    }

    private var shareButton: some View {
        Button {
            Task { await shareCurrentLook() }
        } label: {
            Group {
                if isRenderingShare {
                    ProgressView()
                        .tint(Color.ivory)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.ivory)
                }
            }
            .frame(width: 56, height: 56)
        }
        .glassEffect(.regular, in: .circle)
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
