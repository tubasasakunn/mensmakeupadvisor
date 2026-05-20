import SwiftUI

// Tutorial の眉ステップで表示する type picker。
// 顔型からのおすすめタイプは小さく「★ おすすめ」ラベルで示す。
struct TutorialEyebrowPicker: View {
    @Binding var eyebrowType: EyebrowApplier.BrowType?
    let recommended: String?

    private let options: [(label: String, value: EyebrowApplier.BrowType?)] = [
        ("なし", nil),
        ("ナチュラル", .natural),
        ("ストレート", .straight),
        ("アーチ", .arch),
        ("平行", .parallel),
        ("角度あり", .corner),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("眉のかたち")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.ivory)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in browButton(options[i]) }
                }
                HStack(spacing: 6) {
                    ForEach(3..<6, id: \.self) { i in browButton(options[i]) }
                }
            }
        }
        .aid("tutorial_brow_type_picker")
    }

    private func browButton(_ entry: (label: String, value: EyebrowApplier.BrowType?)) -> some View {
        let isActive = (entry.value == eyebrowType)
        let isRecommended = (entry.value?.rawValue == recommended)
        let aidValue = entry.value?.rawValue ?? "off"

        return Button {
            withAnimation(Theme.Motion.quick) { eyebrowType = entry.value }
        } label: {
            VStack(spacing: 2) {
                Text(entry.label)
                    .font(.system(size: 12, weight: .medium))
                if isRecommended {
                    Text("★ おすすめ")
                        .font(.system(size: 10, weight: .medium))
                }
            }
            .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isActive ? Color.ivory : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isActive ? Color.clear : Theme.Line.outlineIvorySoft,
                        lineWidth: 0.5
                    )
            )
        }
        .accessibilityLabel("眉のかたち\(entry.label)" + (isRecommended ? "、おすすめ" : "") + (isActive ? "、選択中" : ""))
        .aid("tutorial_brow_type_\(aidValue)")
    }
}

#Preview {
    @Previewable @State var b: EyebrowApplier.BrowType? = .natural
    return TutorialEyebrowPicker(eyebrowType: $b, recommended: "natural")
        .padding()
        .background(Color.appBackground)
}
