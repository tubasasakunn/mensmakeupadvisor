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
                Text("♥")
                    .font(.system(size: 14))
                Text("ARCHIVE THIS LOOK")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .kerning(2)
            }
            .foregroundStyle(Color.ivory)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                Rectangle().stroke(Color.lineStrong, lineWidth: 1)
            )
        }
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
                    Text("↑")
                        .font(.system(size: 18, weight: .light, design: .monospaced))
                        .foregroundStyle(Color.ivory)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(Rectangle().stroke(Color.lineStrong, lineWidth: 1))
        }
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
