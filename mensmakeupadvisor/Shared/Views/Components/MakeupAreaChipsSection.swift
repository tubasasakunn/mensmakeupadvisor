import SwiftUI

// ハイライト / シェード / アイ の「どのゾーンに化粧を当てるか」を multi-select
// で選ぶチップ群。Tutorial の各ステップと、将来的に Studio などからも再利用する。
struct MakeupAreaChipsSection: View {
    let title: String
    let layer: MakeupLayer
    @Binding var selected: Set<String>
    let aidPrefix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)

            // 日本語ラベルが入るので 1 列あたり最低 130pt 確保して可読性を担保。
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 6)], spacing: 6) {
                ForEach(areaNames, id: \.self) { name in
                    chip(name)
                }
            }
        }
    }

    private var areaNames: [String] {
        switch layer {
        case .highlight: return MeshAreaLibrary.load(category: .highlight).map(\.name)
        case .shadow:    return MeshAreaLibrary.load(category: .shadow).map(\.name)
        case .eye:       return ["eyeshadow_base", "eyeshadow_crease", "tear_bag", "lower_outer", "eyeliner"]
        case .base, .eyebrow: return []
        }
    }

    private func chip(_ name: String) -> some View {
        let isOn = selected.contains(name)
        return Button {
            withAnimation(.easeInOut(duration: 0.12)) {
                if isOn { selected.remove(name) } else { selected.insert(name) }
            }
        } label: {
            Text(MakeupAreaLabel.display(name))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isOn ? Color.appBackground : Color.ivory)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isOn ? Color.ivory : Color.clear)
                .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
        }
        .aid("\(aidPrefix)_\(name)")
    }
}

#Preview {
    @Previewable @State var hl: Set<String> = ["base_t-zone", "base_c-zone"]
    return MakeupAreaChipsSection(
        title: "HIGHLIGHT AREAS",
        layer: .highlight,
        selected: $hl,
        aidPrefix: "preview_highlight"
    )
    .padding()
    .background(Color.appBackground)
}
