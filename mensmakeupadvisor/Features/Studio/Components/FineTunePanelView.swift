import SwiftUI

// FINE TUNE: 化粧単位ごとの強度スライダー + 眉タイプ選択。
// 各スライダーはその化粧単位の全メッシュに一律の強度を適用する。
// 初心者の認知過負荷を避けるため、主要 4 スライダー + 眉だけを既定で見せ、
// 涙袋 / アイラインは「もっと細かく」で開示する Progressive Disclosure。
struct FineTunePanelView: View {
    @Environment(AppState.self) private var appState
    @State private var showAdvanced = false

    private let primaryKinds: [MakeupKind] = [.base, .highlight, .shadow, .eyeshadow]
    private let advancedKinds: [MakeupKind] = [.tearbag, .eyeliner]

    var body: some View {
        GlassPanel(radius: Theme.Radius.lg, padding: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FINE TUNE")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .kerning(2)
                        .foregroundStyle(Theme.Text.secondaryFaded)
                    Text("細かく調整する")
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.ivory)
                    Text("0 で何もしない、50 が標準、100 で最大")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Text.secondaryFaded)
                }
                .padding(.bottom, Theme.Spacing.lg)

                VStack(spacing: Theme.Spacing.xl) {
                    ForEach(primaryKinds, id: \.self) { kind in
                        kindSliderRow(kind)
                    }
                    browTypeRow

                    advancedDisclosure

                    if showAdvanced {
                        VStack(spacing: Theme.Spacing.xl) {
                            ForEach(advancedKinds, id: \.self) { kind in
                                kindSliderRow(kind)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }

    private var advancedDisclosure: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showAdvanced.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                Text(showAdvanced ? "詳しい項目を閉じる" : "涙袋やアイラインも調整する")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
            }
            .foregroundStyle(Color.inkSecondary)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(showAdvanced ? "詳しい項目を閉じる" : "涙袋やアイラインも調整する")
        .aid("studio_finetune_disclosure")
    }

    private func kindSliderRow(_ kind: MakeupKind) -> some View {
        let value = Double(appState.composition.intensity(of: kind)) * 100

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline) {
                Text(kind.labelJP)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.ivory)
                    .frame(width: 100, alignment: .leading)

                Spacer()

                Text(String(format: "%.0f", value))
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
                    .frame(width: 36, alignment: .trailing)
            }

            HairlineSlider(
                value: Binding(
                    get: { Double(appState.composition.intensity(of: kind)) * 100 },
                    set: { appState.composition.setIntensity(Float($0 / 100), for: kind) }
                ),
                range: 0...100,
                style: .studio
            )
            .accessibilityLabel("\(kind.labelJP)の強さ")
            .accessibilityValue("\(Int(value))")
            .aid("studio_intensity_\(kind.rawValue)")
        }
    }

    private var browTypeRow: some View {
        let options: [(label: String, value: EyebrowApplier.BrowType?)] = [
            ("なし", nil),
            ("ナチュラル", .natural),
            ("ストレート", .straight),
            ("アーチ", .arch),
            ("平行", .parallel),
            ("角度あり", .corner),
        ]
        return VStack(alignment: .leading, spacing: 8) {
            Text("眉のかたち")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.ivory)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 6)], spacing: 6) {
                ForEach(0..<options.count, id: \.self) { i in
                    browTypeButton(options[i])
                }
            }
        }
        .padding(.top, 4)
    }

    private func browTypeButton(_ entry: (label: String, value: EyebrowApplier.BrowType?)) -> some View {
        let isActive = (entry.value == appState.composition.browType)
        let aidValue = entry.value?.rawValue ?? "off"
        return Button {
            withAnimation(Theme.Motion.quick) {
                appState.composition.setBrowType(entry.value)
            }
        } label: {
            Text(entry.label)
                .font(.system(size: 12, weight: .medium))
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
        .accessibilityLabel("眉のかたち\(entry.label)" + (isActive ? "。選択中" : ""))
        .aid("studio_brow_type_\(aidValue)")
    }
}

#Preview {
    FineTunePanelView()
        .environment(AppState())
        .padding()
        .background(Color.appBackground)
}
