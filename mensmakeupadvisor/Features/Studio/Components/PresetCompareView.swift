import SwiftUI
import UIKit

// プリセットを 2 つ選んで並べて比較する。各 composition を engine で
// 非破壊レンダリングし、左右に表示。「使う」で session に適用して閉じる。
//
// engine 未準備 (モック等) では render が失敗するため、renderedImage /
// capturedImage にフォールバックして UI は成立させる。
private enum Layout {
    nonisolated static let previewHeight: CGFloat = 220
}

struct PresetCompareView: View {
    @Environment(AppState.self) private var appState
    let onApply: () -> Void

    @State private var leftID: String = MakeupPreset.all.first?.id ?? "natural"
    @State private var rightID: String = MakeupPreset.all.count > 1 ? MakeupPreset.all[1].id : "kireime"
    @State private var leftImage: UIImage?
    @State private var rightImage: UIImage?
    @State private var isRendering = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                pane(side: "L", presetID: $leftID, image: leftImage)
                pane(side: "R", presetID: $rightID, image: rightImage)
            }
            .overlay {
                if isRendering {
                    ProgressView().tint(Color.ivory)
                }
            }

            Text("左右でプリセットを切り替えて見比べ、好みの方を「使う」")
                .font(Theme.Typography.UI.footnote)
                .foregroundStyle(Theme.Text.primaryFaded)
                .multilineTextAlignment(.center)
        }
        .task(id: "\(leftID)|\(rightID)") { await renderBoth() }
        .aid("studio_compare_view")
    }

    private func pane(side: String, presetID: Binding<String>, image: UIImage?) -> some View {
        let preset = MakeupPreset.all.first { $0.id == presetID.wrappedValue }
        return VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Theme.Surface.imageBackdrop
                if let display = image ?? appState.renderedImage ?? appState.capturedImage {
                    Image(uiImage: display)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(height: Layout.previewHeight)
            .clipShape(.rect(cornerRadius: Theme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(Theme.Line.outlineIvorySoft, lineWidth: Theme.Size.Line.thin)
            )

            // プリセット切替チップ
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(MakeupPreset.all) { p in
                    chip(p.label, selected: p.id == presetID.wrappedValue) {
                        presetID.wrappedValue = p.id
                    }
                }
            }

            if let preset {
                GlassSecondaryButton(
                    title: "このメイクにする",
                    accessibilityID: "studio_compare_apply_\(side.lowercased())"
                ) {
                    Haptics.medium()
                    apply(preset)
                }
            }
        }
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Typography.UI.captionMedium)
                .foregroundStyle(selected ? Theme.Text.onAccent : Color.ivory)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .background(selected ? Color.ivory : Theme.Surface.panel, in: .capsule)
                .overlay(Capsule().stroke(Theme.Line.outlineIvorySoft, lineWidth: Theme.Size.Line.thin))
        }
        .aid("studio_compare_chip_\(label)")
    }

    // MARK: - Render & apply

    private func renderBoth() async {
        isRendering = true
        defer { isRendering = false }
        let base = appState.composition
        if let p = MakeupPreset.all.first(where: { $0.id == leftID }) {
            var c = base
            p.apply(to: &c)
            leftImage = await render(c)
        }
        if let p = MakeupPreset.all.first(where: { $0.id == rightID }) {
            var c = base
            p.apply(to: &c)
            rightImage = await render(c)
        }
    }

    private func render(_ composition: MakeupComposition) async -> UIImage? {
        if let img = try? await appState.makeupEngine.render(composition: composition) {
            return img
        }
        return appState.renderedImage ?? appState.capturedImage
    }

    private func apply(_ preset: MakeupPreset) {
        var c = appState.composition
        preset.apply(to: &c)
        appState.composition = c
        appState.activePresetID = preset.id
        appState.requestMakeupRender()
        onApply()
    }
}
