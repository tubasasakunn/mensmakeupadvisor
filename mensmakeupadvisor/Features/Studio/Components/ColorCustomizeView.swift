import SwiftUI
import UIKit

// メイク種別ごとに色を選び直すカスタマイズ。各メッシュの強度 (alpha) は保ったまま
// RGB だけ差し替える。プレビューは engine で非破壊レンダリング、「適用」で session へ。
private enum Layout {
    nonisolated static let previewHeight: CGFloat = 260
    nonisolated static let swatch: CGFloat = 38
}

struct ColorCustomizeView: View {
    @Environment(AppState.self) private var appState
    let onApply: () -> Void

    // カスタマイズ対象。色が効く種別のみ並べる。
    private let kinds: [MakeupKind] = [.eyeshadow, .eyeliner, .eyebrow, .shadow, .highlight]

    @State private var working: MakeupComposition = .empty
    @State private var loaded = false
    @State private var selectedKind: MakeupKind = .eyeshadow
    @State private var previewImage: UIImage?
    @State private var isRendering = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            previewPane
            kindPicker
            swatchRow

            GlassPrimaryButton(
                title: "この色で確定する",
                accessibilityID: "studio_color_apply_button"
            ) {
                Haptics.medium()
                appState.composition = working
                appState.requestMakeupRender()
                onApply()
            }
        }
        .task {
            guard !loaded else { return }
            working = appState.composition
            loaded = true
            await renderPreview()
        }
        .aid("studio_color_view")
    }

    private var previewPane: some View {
        ZStack {
            Theme.Surface.imageBackdrop
            if let display = previewImage ?? appState.renderedImage ?? appState.capturedImage {
                Image(uiImage: display)
                    .resizable()
                    .scaledToFit()
            }
            if isRendering {
                ProgressView().tint(Color.ivory)
            }
        }
        .frame(height: Layout.previewHeight)
        .clipShape(.rect(cornerRadius: Theme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.Line.outlineIvorySoft, lineWidth: Theme.Size.Line.thin)
        )
    }

    private var kindPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(kinds, id: \.self) { kind in
                    Button {
                        selectedKind = kind
                    } label: {
                        Text(kind.labelJP)
                            .font(Theme.Typography.UI.subheadlineMedium)
                            .foregroundStyle(selectedKind == kind ? Theme.Text.onAccent : Color.ivory)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, 7)
                            .background(selectedKind == kind ? Color.ivory : Theme.Surface.panel, in: .capsule)
                            .overlay(Capsule().stroke(Theme.Line.outlineIvorySoft, lineWidth: Theme.Size.Line.thin))
                    }
                    .aid("studio_color_kind_\(kind.rawValue)")
                }
            }
            .padding(.horizontal, 2)
        }
        .aid("studio_color_kind_picker")
    }

    private var swatchRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(palette(for: selectedKind)) { option in
                Button {
                    Haptics.soft()
                    recolor(selectedKind, to: option.rgb)
                } label: {
                    Circle()
                        .fill(option.color)
                        .frame(width: Layout.swatch, height: Layout.swatch)
                        .overlay(Circle().stroke(Theme.Line.outlineIvory, lineWidth: Theme.Size.Line.regular))
                }
                .accessibilityLabel(option.name)
                .aid("studio_color_swatch_\(option.name)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recolor & render

    private func recolor(_ kind: MakeupKind, to rgb: RGB) {
        guard var unit = working.unit(kind) else { return }
        if kind.isMeshBased {
            for (id, color) in unit.meshColors {
                unit.meshColors[id] = MeshColor(r: rgb.r, g: rgb.g, b: rgb.b, a: color.a)
            }
        } else {
            unit.tint = MeshColor(r: rgb.r, g: rgb.g, b: rgb.b, a: unit.tint.a)
        }
        working.setUnit(unit)
        Task { await renderPreview() }
    }

    private func renderPreview() async {
        isRendering = true
        defer { isRendering = false }
        if let img = try? await appState.makeupEngine.render(composition: working) {
            previewImage = img
        }
    }

    // MARK: - Palettes

    private struct ColorOption: Identifiable {
        let id = UUID()
        let name: String
        let rgb: RGB
        var color: Color {
            Color(red: Double(rgb.r) / 255, green: Double(rgb.g) / 255, blue: Double(rgb.b) / 255)
        }
    }

    private func palette(for kind: MakeupKind) -> [ColorOption] {
        switch kind {
        case .eyeshadow:
            [.init(name: "brown", rgb: RGB(190, 145, 120)),
             .init(name: "pink", rgb: RGB(205, 150, 150)),
             .init(name: "khaki", rgb: RGB(150, 150, 110)),
             .init(name: "gray", rgb: RGB(140, 140, 150))]
        case .eyeliner:
            [.init(name: "black", rgb: RGB(35, 20, 10)),
             .init(name: "brown", rgb: RGB(80, 55, 35)),
             .init(name: "gray", rgb: RGB(90, 90, 100))]
        case .eyebrow:
            [.init(name: "darkbrown", rgb: RGB(90, 65, 45)),
             .init(name: "ash", rgb: RGB(110, 100, 90)),
             .init(name: "natural", rgb: RGB(120, 90, 65)),
             .init(name: "black", rgb: RGB(45, 35, 30))]
        case .shadow:
            [.init(name: "warm", rgb: RGB(139, 90, 43)),
             .init(name: "neutral", rgb: RGB(120, 95, 80)),
             .init(name: "cool", rgb: RGB(110, 100, 110))]
        case .highlight:
            [.init(name: "white", rgb: RGB(255, 255, 255)),
             .init(name: "champagne", rgb: RGB(250, 235, 205)),
             .init(name: "pink", rgb: RGB(250, 225, 225))]
        default:
            [.init(name: "default", rgb: RGB(kind.defaultColor.r, kind.defaultColor.g, kind.defaultColor.b))]
        }
    }

    private struct RGB {
        let r: Float, g: Float, b: Float
        init(_ r: Float, _ g: Float, _ b: Float) { self.r = r; self.g = g; self.b = b }
    }
}
